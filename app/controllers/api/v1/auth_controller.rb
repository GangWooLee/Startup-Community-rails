# frozen_string_literal: true

# 앱 세션 동기화 API
#
# Hotwire Native 앱에서 세션을 동기화하는 API입니다.
# 앱 재시작 시 Keychain/Keystore에 저장된 토큰으로 자동 로그인합니다.
#
# @example 토큰 발급 (로그인 성공 후)
#   POST /api/v1/auth/token
#   Response: { token: "eyJ...", expires_at: "2026-02-21T..." }
#
# @example 토큰 검증 (앱 시작 시)
#   GET /api/v1/auth/validate
#   Headers: Authorization: Bearer <token>
#   Response: { valid: true, user: { id: 1, name: "..." } }
#
# @example 토큰 폐기 (로그아웃 시)
#   DELETE /api/v1/auth/token
#
module Api
  module V1
    class AuthController < ApplicationController
      # API 공통 Concern
      include Api::Authenticatable
      include Api::JsonResponse

      # API 전용 설정
      skip_before_action :verify_authenticity_token
      before_action :require_hotwire_native_app

      # 토큰 검증은 Bearer 토큰으로
      before_action :authenticate_with_token!, only: [ :validate, :destroy ]
      # 토큰 발급은 세션 인증으로
      before_action :require_login, only: [ :create ]

      # 토큰 만료 시간 (30일)
      TOKEN_EXPIRY_DAYS = 30

      # POST /api/v1/auth/token
      # 세션 기반 인증 후 앱용 토큰 발급
      def create
        # Rails signed token 생성 (유효기간 30일)
        token = generate_auth_token(current_user)
        expires_at = TOKEN_EXPIRY_DAYS.days.from_now

        render json: {
          success: true,
          token: token,
          expires_at: expires_at.iso8601,
          user: user_response(current_user)
        }, status: :created
      end

      # GET /api/v1/auth/validate
      # Bearer 토큰 검증 및 사용자 정보 반환
      def validate
        render json: {
          valid: true,
          user: user_response(@authenticated_user)
        }
      end

      # DELETE /api/v1/auth/token
      # 토큰 폐기 (로그아웃)
      def destroy
        # Signed token은 서버 측 상태가 없어 실제 폐기 불가
        # 클라이언트에서 토큰 삭제하면 됨
        # 향후 토큰 블랙리스트 구현 가능

        render json: {
          success: true,
          message: "Token revoked. Please remove it from device storage."
        }
      end

      private

      # Rails signed token 생성
      # @param user [User] 사용자
      # @return [String] JWT 형식의 signed token
      def generate_auth_token(user)
        # Rails MessageVerifier를 사용한 토큰 생성
        payload = {
          user_id: user.id,
          exp: TOKEN_EXPIRY_DAYS.days.from_now.to_i,
          iat: Time.current.to_i,
          purpose: "app_session"
        }

        Rails.application.message_verifier("app_session").generate(payload, purpose: :app_session)
      end

      # 토큰 검증 및 사용자 로드
      def authenticate_with_token!
        token = extract_bearer_token

        if token.blank?
          return render_unauthorized("Missing authorization token")
        end

        begin
          payload = Rails.application.message_verifier("app_session").verify(token, purpose: :app_session)
          payload = payload.with_indifferent_access if payload.is_a?(Hash)

          # 만료 확인 (exp 필드가 없거나 만료된 경우)
          if payload[:exp].blank? || payload[:exp] < Time.current.to_i
            return render_unauthorized("Token expired")
          end

          @authenticated_user = User.find_by(id: payload[:user_id])

          unless @authenticated_user
            return render_unauthorized("User not found") # rubocop:disable Style/RedundantReturn
          end
        rescue ActiveSupport::MessageVerifier::InvalidSignature
          return render_unauthorized("Invalid token") # rubocop:disable Style/RedundantReturn
        end
      end

      # Authorization 헤더에서 Bearer 토큰 추출
      # Rails MessageVerifier 토큰은 Base64 인코딩 + "--" 구분자 형식
      def extract_bearer_token
        auth_header = request.headers["Authorization"]
        return nil unless auth_header.present?

        # Bearer 형식 검증: "Bearer <token>" (토큰은 Base64 + 구분자 허용)
        match = auth_header.match(/\ABearer\s+([a-zA-Z0-9_=+\/-]+(?:--[a-zA-Z0-9_=+\/-]+)*)\z/i)
        match ? match[1] : nil
      end

      # 사용자 정보 응답 구조
      def user_response(user)
        {
          id: user.id,
          name: user.display_name,
          email: user.email,
          avatar_url: avatar_url_for(user),
          is_anonymous: user.is_anonymous
        }
      end

      # 아바타 URL 생성
      def avatar_url_for(user)
        if user.avatar.attached?
          url_for(user.avatar)
        elsif user.using_anonymous_avatar?
          "/anonymous#{user.avatar_type}-80.png"
        else
          nil
        end
      end

      # require_hotwire_native_app - Api::Authenticatable concern에서 제공
      # require_login - Api::Authenticatable concern에서 제공
      # render_unauthorized - Api::JsonResponse concern에서 제공
    end
  end
end
