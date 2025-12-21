class LikesController < ApplicationController
  before_action :require_login_for_like
  before_action :set_post

  # POST /posts/:post_id/like
  def toggle
    liked = @post.toggle_like!(current_user)
    @post.reload # counter_cache 업데이트 반영

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "like-button-#{@post.id}",
          partial: "shared/like_button",
          locals: { post: @post, liked: @post.liked_by?(current_user) }
        )
      end
      format.html { redirect_back fallback_location: post_path(@post) }
      format.json do
        render json: {
          liked: @post.liked_by?(current_user),
          likes_count: @post.likes_count
        }
      end
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  # JSON 요청 시 401 상태 코드 반환, 그 외는 로그인 페이지로 리다이렉트
  def require_login_for_like
    unless logged_in?
      respond_to do |format|
        format.json { render json: { error: "로그인이 필요합니다." }, status: :unauthorized }
        format.html { redirect_to login_path, alert: "로그인이 필요합니다." }
        format.turbo_stream { redirect_to login_path, alert: "로그인이 필요합니다." }
      end
    end
  end
end
