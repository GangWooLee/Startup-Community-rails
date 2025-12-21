# frozen_string_literal: true

# Bookmarkable concern - 스크랩 기능을 위한 공통 모듈
# Post 모델에서 include하여 사용
module Bookmarkable
  extend ActiveSupport::Concern

  included do
    has_many :bookmarks, as: :bookmarkable, dependent: :destroy
  end

  # 특정 사용자가 스크랩했는지 확인
  def bookmarked_by?(user)
    return false unless user
    bookmarks.exists?(user_id: user.id)
  end

  # 스크랩 토글 (스크랩 추가/취소)
  # @return [Boolean, nil] true: 추가됨, false: 취소됨, nil: 사용자 없음
  # 보안: 트랜잭션 + 비관적 잠금으로 Race Condition 방지
  def toggle_bookmark!(user)
    return nil unless user

    self.class.transaction do
      # 비관적 잠금으로 동시 요청 처리
      existing_bookmark = bookmarks.lock.find_by(user_id: user.id)
      if existing_bookmark
        existing_bookmark.destroy
        false # 스크랩 취소됨
      else
        bookmarks.create!(user_id: user.id)
        true # 스크랩 추가됨
      end
    end
  rescue ActiveRecord::RecordNotUnique
    # 유니크 제약 위반 시 (이미 스크랩 존재) - 무시
    false
  end

  # 스크랩 수
  def bookmarks_count
    bookmarks.count
  end
end
