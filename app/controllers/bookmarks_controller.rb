class BookmarksController < ApplicationController
  before_action :require_login_for_bookmark
  before_action :set_post

  # POST /posts/:id/bookmark
  def toggle
    bookmarked = @post.toggle_bookmark!(current_user)

    respond_to do |format|
      format.turbo_stream do
        streams = [
          turbo_stream.replace(
            "bookmark-button-#{@post.id}",
            partial: "shared/bookmark_button",
            locals: { post: @post, bookmarked: @post.bookmarked_by?(current_user) }
          )
        ]
        # GA4 스크랩 이벤트 (스크랩 추가 시에만, 프로덕션에서만)
        if bookmarked && Rails.env.production?
          streams << turbo_stream.append("ga4-events") do
            "<script>if(typeof gtag==='function'){gtag('event','bookmark_post',{post_id:#{@post.id}});}</script>".html_safe
          end
        end
        render turbo_stream: streams
      end
      format.html do
        track_ga4_event("bookmark_post", { post_id: @post.id }) if bookmarked
        redirect_back fallback_location: post_path(@post)
      end
      format.json do
        render json: {
          bookmarked: @post.bookmarked_by?(current_user),
          bookmarks_count: @post.bookmarks_count
        }
      end
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  # JSON 요청 시 401 상태 코드 반환, 그 외는 로그인 페이지로 리다이렉트
  def require_login_for_bookmark
    unless logged_in?
      respond_to do |format|
        format.json { render json: { error: "로그인이 필요합니다." }, status: :unauthorized }
        format.html { redirect_to login_path, alert: "로그인이 필요합니다." }
        format.turbo_stream { redirect_to login_path, alert: "로그인이 필요합니다." }
      end
    end
  end
end
