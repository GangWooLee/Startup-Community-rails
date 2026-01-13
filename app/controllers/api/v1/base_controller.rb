# frozen_string_literal: true

# API v1 베이스 컨트롤러
# 용도: n8n 등 외부 서비스 연동 (커뮤니티 초기 활성화용)
# 제거: 이 파일 + posts_controller.rb 삭제 + routes.rb에서 api 블록 제거
module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_token!

      private

      # Bearer 토큰 인증
      # @return [void]
      # @raise [render 401] 토큰이 없거나 유효하지 않은 경우
      def authenticate_api_token!
        token = extract_bearer_token
        @current_api_user = User.find_by(api_token: token) if token.present?

        unless @current_api_user
          render json: {
            error: "Unauthorized",
            message: "Invalid or missing API token"
          }, status: :unauthorized
        end
      end

      # Authorization 헤더에서 Bearer 토큰 추출
      # @return [String, nil] 토큰 또는 nil
      def extract_bearer_token
        auth_header = request.headers["Authorization"]
        return nil unless auth_header.present?

        # "Bearer <token>" 형식에서 토큰 추출
        auth_header.gsub(/^Bearer\s+/i, "").presence
      end

      attr_reader :current_api_user
    end
  end
end
