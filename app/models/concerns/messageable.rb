# frozen_string_literal: true

# 메시지/채팅 관련 메서드
# User 모델에서 추출된 concern
#
# @note unread_count 컬럼을 직접 사용하여 성능 최적화
#       messages 테이블 조인 없이 단일 SUM/EXISTS 쿼리로 처리
module Messageable
  extend ActiveSupport::Concern

  # 읽지 않은 메시지 총 수 (N+1 방지: 단일 SUM 쿼리)
  # unread_count 컬럼을 직접 합산하여 성능 최적화
  #
  # @return [Integer] 읽지 않은 메시지 수
  def total_unread_messages
    chat_room_participants
      .where(deleted_at: nil)
      .sum(:unread_count)
  end

  # 읽지 않은 메시지가 있는지 확인 (EXISTS로 최적화)
  # SQLite/PostgreSQL 호환: 반드시 boolean 반환
  #
  # @return [Boolean] 읽지 않은 메시지 존재 여부
  def has_unread_messages?
    chat_room_participants
      .where(deleted_at: nil)
      .where("unread_count > 0")
      .exists?
  end
end
