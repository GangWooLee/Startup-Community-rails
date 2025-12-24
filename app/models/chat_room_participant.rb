class ChatRoomParticipant < ApplicationRecord
  belongs_to :chat_room
  belongs_to :user

  validates :user_id, uniqueness: { scope: :chat_room_id }

  # 삭제되지 않은 참여자만 조회
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  # 안읽은 메시지 수
  def unread_count
    base_time = last_read_at || Time.at(0)
    chat_room.messages
             .where.not(sender_id: user_id)
             .where("created_at > ?", base_time)
             .count
  end

  # 읽음 처리
  def mark_as_read!
    update!(last_read_at: Time.current)
  end

  # 소프트 삭제 (사용자에게만 숨김)
  def soft_delete!
    update!(deleted_at: Time.current)
  end

  # 삭제 복구 (새 메시지가 오면 자동 복구)
  def restore!
    update!(deleted_at: nil)
  end

  def deleted?
    deleted_at.present?
  end
end
