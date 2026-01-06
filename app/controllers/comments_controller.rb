class CommentsController < ApplicationController
  before_action :require_login
  before_action :set_post
  before_action :set_comment, only: [:destroy, :like]
  before_action :authorize_comment, only: [:destroy]

  # POST /posts/:post_id/comments
  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    respond_to do |format|
      if @comment.save
        # GA4 댓글 작성 이벤트 데이터 저장 (Turbo Stream에서 사용)
        @ga4_event = {
          name: "comment_create",
          params: { post_id: @post.id, is_reply: @comment.parent_id.present? }
        }
        format.turbo_stream { render_comment_turbo_stream(:create) }
        format.html do
          track_ga4_event("comment_create", { post_id: @post.id, is_reply: @comment.parent_id.present? })
          redirect_to post_path(@post), notice: "댓글이 작성되었습니다."
        end
        format.json { render json: comment_json(@comment), status: :created }
      else
        format.html { redirect_to post_path(@post), alert: @comment.errors.full_messages.join(", ") }
        format.json { render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/:post_id/comments/:id
  def destroy
    @comment.destroy

    respond_to do |format|
      format.turbo_stream { render_comment_turbo_stream(:destroy) }
      format.html { redirect_to post_path(@post), notice: "댓글이 삭제되었습니다." }
      format.json { render json: { success: true, comments_count: @post.reload.comments_count } }
    end
  end

  # POST /posts/:post_id/comments/:id/like
  def like
    liked = @comment.toggle_like!(current_user)

    respond_to do |format|
      format.turbo_stream { render_like_turbo_stream(liked) }
      format.html { redirect_back fallback_location: post_path(@post) }
      format.json do
        render json: {
          liked: @comment.liked_by?(current_user),
          likes_count: @comment.likes_count
        }
      end
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_comment
    @comment = @post.comments.find(params[:id])
  end

  def authorize_comment
    unless @comment.user_id == current_user.id
      respond_to do |format|
        format.html { redirect_to post_path(@post), alert: "권한이 없습니다." }
        format.json { render json: { error: "권한이 없습니다." }, status: :forbidden }
      end
    end
  end

  def require_login
    unless logged_in?
      respond_to do |format|
        format.html { redirect_to login_path, alert: "로그인이 필요합니다." }
        format.json { render json: { error: "로그인이 필요합니다." }, status: :unauthorized }
      end
    end
  end

  def comment_params
    params.require(:comment).permit(:content, :parent_id)
  end

  def comment_json(comment)
    {
      id: comment.id,
      content: comment.content,
      user: {
        id: comment.user.id,
        name: comment.user.name,
        avatar_url: comment.user.avatar_url
      },
      parent_id: comment.parent_id,
      likes_count: comment.likes_count,
      liked: comment.liked_by?(current_user),
      replies_count: comment.replies.count,
      created_at: comment.created_at.iso8601,
      is_owner: comment.user_id == current_user.id
    }
  end

  def render_comment_turbo_stream(action)
    # GA4 이벤트 스크립트 (프로덕션에서만)
    ga4_script = if Rails.env.production? && @ga4_event.present?
      turbo_stream.append("ga4-events") do
        "<script>if(typeof gtag==='function'){gtag('event','#{@ga4_event[:name]}',#{@ga4_event[:params].to_json});}</script>".html_safe
      end
    end

    case action
    when :create
      if @comment.reply?
        streams = [
          turbo_stream.append(
            "replies-#{@comment.parent_id}",
            partial: "comments/comment",
            locals: { comment: @comment, post: @post, current_user: current_user }
          )
        ]
        streams << ga4_script if ga4_script
        render turbo_stream: streams
      else
        streams = [
          turbo_stream.append(
            "comments-list",
            partial: "comments/comment",
            locals: { comment: @comment, post: @post, current_user: current_user }
          ),
          turbo_stream.update("comments-count", @post.reload.comments_count.to_s),
          turbo_stream.replace("comment-form", partial: "comments/form", locals: { post: @post, comment: Comment.new }),
          turbo_stream.remove("comments-empty")
        ]
        streams << ga4_script if ga4_script
        render turbo_stream: streams
      end
    when :destroy
      render turbo_stream: [
        turbo_stream.remove("comment-#{@comment.id}"),
        turbo_stream.update("comments-count", @post.reload.comments_count.to_s)
      ]
    end
  end

  def render_like_turbo_stream(liked)
    render turbo_stream: turbo_stream.replace(
      "comment-like-button-#{@comment.id}",
      partial: "comments/like_button_icon",
      locals: { comment: @comment, liked: @comment.liked_by?(current_user) }
    )
  end
end
