class ProfilesController < ApplicationController
  def show
    # N+1 쿼리 방지를 위해 includes 사용
    @user = User.includes(:posts)
                .find(params[:id])

    # 각 탭별 데이터 (최신순, 제한)
    # 커뮤니티 글 (free, question, promotion)
    @posts = @user.posts.published.where(category: [:free, :question, :promotion]).recent.limit(PROFILE_POSTS_LIMIT)

    # 외주 글 (hiring, seeking)
    @outsourcing_posts = @user.posts.published.where(category: [:hiring, :seeking]).recent.limit(PROFILE_POSTS_LIMIT)

    # 현재 사용자가 본인 프로필인지 확인
    @is_own_profile = logged_in? && current_user.id == @user.id
  end
end
