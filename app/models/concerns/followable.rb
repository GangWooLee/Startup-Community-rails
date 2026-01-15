# frozen_string_literal: true

# 팔로우 관계 관련 메서드
# User 모델에서 추출된 concern
module Followable
  extend ActiveSupport::Concern

  # 특정 사용자를 팔로우 중인지 확인
  def following?(other_user)
    following.include?(other_user)
  end

  # 팔로우하기
  def follow(other_user)
    return false if self == other_user
    active_follows.find_or_create_by(followed: other_user)
  end

  # 언팔로우
  def unfollow(other_user)
    active_follows.find_by(followed: other_user)&.destroy
  end

  # 팔로우 토글 (팔로우 중이면 언팔, 아니면 팔로우)
  def toggle_follow!(other_user)
    if following?(other_user)
      unfollow(other_user)
      false
    else
      follow(other_user)
      true
    end
  end
end
