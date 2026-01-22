# frozen_string_literal: true

# API 응답 형식 표준화 Concern
#
# 모든 API 응답을 일관된 형식으로 제공합니다.
#
# @example 성공 응답
#   render_success(data: { user: user_data }, message: "Created")
#   # => { success: true, data: { user: {...} }, message: "Created" }
#
# @example 에러 응답
#   render_error(message: "Not found", errors: ["User not found"], status: :not_found)
#   # => { success: false, message: "Not found", errors: ["User not found"] }
#
module Api
  module JsonResponse
    extend ActiveSupport::Concern

    private

    # 성공 응답 렌더링
    #
    # @param data [Hash, nil] 응답 데이터
    # @param message [String, nil] 성공 메시지
    # @param status [Symbol] HTTP 상태 코드 (기본: :ok)
    def render_success(data: nil, message: nil, status: :ok)
      response = { success: true }
      response[:data] = data if data.present?
      response[:message] = message if message.present?

      render json: response, status: status
    end

    # 에러 응답 렌더링
    #
    # @param message [String] 에러 메시지
    # @param errors [Array<String>] 상세 에러 목록
    # @param status [Symbol] HTTP 상태 코드 (기본: :unprocessable_entity)
    def render_error(message:, errors: [], status: :unprocessable_entity)
      render json: {
        success: false,
        message: message,
        errors: errors
      }, status: status
    end

    # 인증 실패 응답 (401)
    #
    # @param message [String] 에러 메시지
    def render_unauthorized(message)
      render json: {
        valid: false,
        message: message
      }, status: :unauthorized
    end

    # 권한 없음 응답 (403)
    #
    # @param message [String] 에러 메시지
    def render_forbidden(message)
      render json: {
        success: false,
        message: message
      }, status: :forbidden
    end

    # 리소스 없음 응답 (404)
    #
    # @param message [String] 에러 메시지
    def render_not_found(message = "Resource not found")
      render json: {
        success: false,
        message: message
      }, status: :not_found
    end
  end
end
