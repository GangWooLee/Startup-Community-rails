class MyPageController < ApplicationController
  before_action :require_login
  before_action :hide_floating_button, only: [:edit]

  def show
    @user = User.includes(:posts, :bookmarks).find(current_user.id)

    # 내가 작성한 글 (커뮤니티 / 외주 분리)
    my_posts = @user.posts.published.recent.limit(PROFILE_POSTS_LIMIT)
    @my_community_posts = my_posts.select(&:community?)
    @my_outsourcing_posts = my_posts.select(&:outsourcing?)

    # 내가 북마크한 글 (커뮤니티 / 외주 분리)
    bookmarked_posts = @user.bookmarks
                            .includes(:bookmarkable)
                            .recent
                            .limit(PROFILE_POSTS_LIMIT)
                            .map(&:bookmarkable)
                            .compact
    @bookmarked_community_posts = bookmarked_posts.select { |p| p.is_a?(Post) && p.community? }
    @bookmarked_outsourcing_posts = bookmarked_posts.select { |p| p.is_a?(Post) && p.outsourcing? }
  end

  def edit
    @user = current_user
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
