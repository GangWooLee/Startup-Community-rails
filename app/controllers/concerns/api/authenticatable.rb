# frozen_string_literal: true

# API 인증 관련 공통 메서드를 제공하는 Concern
# 사용법: include Api::Authenticatable
#
# 제공 메서드:
# - require_hotwire_native_app: Hotwire Native 앱에서만 접근 허용
# - require_login: 로그인 필수 체크
# - extract_bearer_token: Authorization 헤더에서 Bearer 토큰 추출
# - hotwire_native_app?: 현재 요청이 네이티브 앱에서 온 것인지 확인
#
# @example
#   class Api::V1::DevicesController < ApplicationController
#     include Api::Authenticatable
#     before_action :require_hotwire_native_app
#     before_action :require_login
#   end
module Api
  module Authenticatable
    extend ActiveSupport::Concern

    private

    # Hotwire Native 앱에서만 접근 가능하도록 제한
    # @note before_action으로 사용
    def require_hotwire_native_app
      return if hotwire_native_app?

      render json: {
        success: false,
        message: "This API is only available for native apps"
      }, status: :forbidden
    end

    # 로그인 필수 체크
    # @note before_action으로 사용
    def require_login
      return if logged_in?

      render json: {
        success: false,
        message: "Authentication required"
      }, status: :unauthorized
    end

    # Authorization 헤더에서 Bearer 토큰 추출
    # @return [String, nil] 토큰 문자열 또는 nil
    # @example
    #   Authorization: Bearer abc123xyz...
    #   => "abc123xyz..."
    def extract_bearer_token
      auth_header = request.headers["Authorization"]
      return nil unless auth_header.present?

      # Bearer 토큰 형식 검증 (알파벳, 숫자, 특수문자 허용)
      # Rails MessageVerifier 토큰 형식: base64--hmac
      match = auth_header.match(/\ABearer\s+([a-zA-Z0-9_=+\/-]+(?:--[a-zA-Z0-9_=+\/-]+)*)\z/i)
      match ? match[1] : nil
    end

    # 현재 요청이 Hotwire Native 앱에서 온 것인지 확인
    # @return [Boolean]
    def hotwire_native_app?
      request.user_agent&.include?("Turbo Native")
    end
  end
end
