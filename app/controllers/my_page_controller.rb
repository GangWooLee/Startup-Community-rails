class MyPageController < ApplicationController
  before_action :require_login
  before_action :hide_floating_button, only: [:edit]

  def show
    @user = current_user

    # 내가 작성한 글 (커뮤니티 / 외주 분리) - N+1 방지
    my_posts = @user.posts.published
                    .includes(:user, images_attachments: :blob)
                    .recent.limit(PROFILE_POSTS_LIMIT)
    @my_community_posts = my_posts.select(&:community?)
    @my_outsourcing_posts = my_posts.select(&:outsourcing?)

    # 내가 북마크한 글 (커뮤니티 / 외주 분리) - N+1 방지
    # bookmarkable의 user와 images를 함께 로드
    bookmarked_post_ids = @user.bookmarks
                               .where(bookmarkable_type: "Post")
                               .recent
                               .limit(PROFILE_POSTS_LIMIT)
                               .pluck(:bookmarkable_id)

    bookmarked_posts = Post.where(id: bookmarked_post_ids)
                           .includes(:user, images_attachments: :blob)

    @bookmarked_community_posts = bookmarked_posts.select(&:community?)
    @bookmarked_outsourcing_posts = bookmarked_posts.select(&:outsourcing?)
  end

  def edit
    @user = current_user
  end

  def idea_analyses
    @user = current_user
    @idea_analyses = @user.idea_analyses.order(created_at: :desc)
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to my_page_path, notice: "프로필이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(
      :name, :role_title, :bio, :avatar,
      :affiliation, :skills, :custom_status,
      :linkedin_url, :github_url, :portfolio_url,
      availability_statuses: []
    )
  end
end
