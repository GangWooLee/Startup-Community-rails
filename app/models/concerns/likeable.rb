# frozen_string_literal: true

# Likeable concern - 좋아요 기능을 위한 공통 모듈
# Post, Comment 모델에서 include하여 사용
module Likeable
  extend ActiveSupport::Concern

  included do
    has_many :likes, as: :likeable, dependent: :destroy
  end

  # 특정 사용자가 좋아요를 눌렀는지 확인
  def liked_by?(user)
    return false unless user
    likes.exists?(user_id: user.id)
  end

  # 좋아요 토글 (좋아요 추가/취소)
  # @return [Boolean, nil] true: 추가됨, false: 취소됨, nil: 사용자 없음
  # 보안: 트랜잭션 + 비관적 잠금으로 Race Condition 방지
  def toggle_like!(user)
    return nil unless user

    self.class.transaction do
      # 비관적 잠금으로 동시 요청 처리
      existing_like = likes.lock.find_by(user_id: user.id)
      if existing_like
        existing_like.destroy
        false # 좋아요 취소됨
      else
        # find_or_create_by로 중복 생성 방지
        likes.create!(user_id: user.id)
        true # 좋아요 추가됨
      end
    end
  rescue ActiveRecord::RecordNotUnique
    # 유니크 제약 위반 시 (이미 좋아요 존재) - 무시
    false
  end
end
