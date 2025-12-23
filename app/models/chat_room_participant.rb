class ChatRoomParticipant < ApplicationRecord
  belongs_to :chat_room
  belongs_to :user

  validates :user_id, uniqueness: { scope: :chat_room_id }

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
end
