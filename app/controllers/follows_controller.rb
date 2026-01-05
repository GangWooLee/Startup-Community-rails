# frozen_string_literal: true

# FollowsController - 팔로우/언팔로우 토글 처리
# Turbo Stream으로 팔로우 버튼을 실시간 업데이트합니다.
class FollowsController < ApplicationController
  before_action :require_login
  before_action :set_user

  # POST /profiles/:id/follow
  # 팔로우 토글 (팔로우 중이면 언팔, 아니면 팔로우)
  def toggle
    is_now_following = current_user.toggle_follow!(@user)
    @user.reload  # counter_cache 갱신 반영

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "follow-button-#{@user.id}",
          partial: "profiles/follow_button",
          locals: { user: @user, following: is_now_following }
        )
      end
      format.html { redirect_back fallback_location: profile_path(@user) }
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
