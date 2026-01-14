# frozen_string_literal: true

# API v1 댓글 컨트롤러
# 용도: n8n 자동 댓글 생성 (커뮤니티 초기 활성화용)
module Api
  module V1
    class CommentsController < BaseController
      before_action :set_post

      # POST /api/v1/posts/:post_id/comments
      # @param [Hash] comment 댓글 파라미터
      # @option comment [String] content 내용 (필수, 최대 1000자)
      def create
        @comment = @post.comments.build(comment_params)
        @comment.user = current_api_user

        if @comment.save
          render json: success_response, status: :created
        else
          render json: error_response, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "[API] Comment creation failed: #{e.message}"
        render json: {
          success: false,
          error: "Internal Server Error",
          message: "댓글 생성 중 오류가 발생했습니다"
        }, status: :internal_server_error
      end

      private

      def set_post
        @post = Post.published.find(params[:post_id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: "Not Found",
          message: "게시글을 찾을 수 없습니다"
        }, status: :not_found
      end

      def comment_params
        params.require(:comment).permit(:content)
      end

      def success_response
        {
          success: true,
          comment: {
            id: @comment.id,
            content: @comment.content,
            post_id: @post.id,
            user_id: @comment.user_id,
            created_at: @comment.created_at.iso8601
          }
        }
      end

      def error_response
        {
          success: false,
          errors: @comment.errors.full_messages
        }
      end
    end
  end
end
