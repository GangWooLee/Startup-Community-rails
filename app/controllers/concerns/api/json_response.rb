# frozen_string_literal: true

# API JSON 응답 형식을 표준화하는 Concern
# 사용법: include Api::JsonResponse
#
# 모든 응답은 다음 형식을 따름:
# {
#   "success": true/false,
#   "data": { ... },      # 성공 시
#   "message": "...",     # 선택적 메시지
#   "errors": [...]       # 실패 시 에러 목록
# }
#
# @example
#   class Api::V1::PostsController < ApplicationController
#     include Api::JsonResponse
#
#     def create
#       @post = Post.new(post_params)
#       if @post.save
#         render_success(data: @post, message: "Post created", status: :created)
#       else
#         render_error(message: "Validation failed", errors: @post.errors.full_messages)
#       end
#     end
#   end
module Api
  module JsonResponse
    extend ActiveSupport::Concern

    private

    # 성공 응답 렌더링
    # @param data [Object, nil] 응답 데이터 (JSON 직렬화 가능)
    # @param message [String, nil] 성공 메시지
    # @param status [Symbol] HTTP 상태 코드 (기본: :ok)
    def render_success(data: nil, message: nil, status: :ok)
      response_body = { success: true }
      response_body[:data] = data if data.present?
      response_body[:message] = message if message.present?

      render json: response_body, status: status
    end

    # 에러 응답 렌더링
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

    # 인증 실패 응답 (401 Unauthorized)
    # @param message [String] 에러 메시지 (기본: "Unauthorized")
    def render_unauthorized(message = "Unauthorized")
      render json: {
        success: false,
        message: message
      }, status: :unauthorized
    end

    # 권한 없음 응답 (403 Forbidden)
    # @param message [String] 에러 메시지 (기본: "Forbidden")
    def render_forbidden(message = "Forbidden")
      render json: {
        success: false,
        message: message
      }, status: :forbidden
    end

    # 리소스 없음 응답 (404 Not Found)
    # @param message [String] 에러 메시지 (기본: "Not found")
    def render_not_found(message = "Not found")
      render json: {
        success: false,
        message: message
      }, status: :not_found
    end

    # 서버 에러 응답 (500 Internal Server Error)
    # @param message [String] 에러 메시지 (기본: "Internal server error")
    # @note 프로덕션에서는 상세 에러를 숨기고 로그만 기록
    def render_server_error(message = "Internal server error")
      render json: {
        success: false,
        message: message
      }, status: :internal_server_error
    end
  end
end
