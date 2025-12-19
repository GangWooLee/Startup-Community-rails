class MyPageController < ApplicationController
  before_action :require_login

  def show
    @user = User.includes(:posts, :bookmarks).find(current_user.id)

    # 내가 작성한 글 (최근 10개)
    @my_posts = @user.posts.published.recent.limit(10)

    # 내가 북마크한 글 (최근 10개)
    @bookmarked_posts = @user.bookmarks
                             .includes(:bookmarkable)
                             .recent
                             .limit(10)
                             .map(&:bookmarkable)
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
      :open_chat_url, :github_url, :portfolio_url,
      availability_statuses: []
    )
  end
end
