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
end
