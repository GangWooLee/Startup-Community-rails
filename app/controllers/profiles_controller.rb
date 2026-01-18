class ProfilesController < ApplicationController
  before_action :hide_floating_button

  def show
    # N+1 쿼리 방지를 위해 includes 사용 (아바타, 커버 이미지만 로드)
    @user = User.includes(avatar_attachment: :blob, cover_image_attachment: :blob)
                .find(params[:id])

    # 각 탭별 데이터 (최신순, 제한)
    # 커뮤니티 글 (free, question, promotion)
    @posts = @user.posts.published
                  .includes(images_attachments: :blob)
                  .where(category: [ :free, :question, :promotion ])
                  .recent.limit(PROFILE_POSTS_LIMIT)

    # 외주 글 (hiring, seeking)
    @outsourcing_posts = @user.posts.published
                              .includes(images_attachments: :blob)
                              .where(category: [ :hiring, :seeking ])
                              .recent.limit(PROFILE_POSTS_LIMIT)

    # 현재 사용자가 본인 프로필인지 확인
    @is_own_profile = logged_in? && current_user.id == @user.id

    # 프라이버시 블러 처리를 위한 viewer 설정
    @viewer = current_user

    # 팔로우 상태 확인 (로그인 시)
    @is_following = logged_in? && current_user.following?(@user)
  end
end
