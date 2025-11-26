class ProfilesController < ApplicationController
  def show
    # N+1 쿼리 방지를 위해 includes 사용
    @user = User.includes(:posts, :job_posts, :talent_listings)
                .find(params[:id])

    # 각 탭별 데이터 (최신순, 제한)
    @posts = @user.posts.published.recent.limit(10)
    @job_posts = @user.job_posts.recent.limit(10)
    @talent_listings = @user.talent_listings.recent.limit(10)

    # TODO: 로그인 기능 구현 후 current_user로 변경
    @is_own_profile = false
  end
end
