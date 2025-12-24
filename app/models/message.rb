class Message < ApplicationRecord
  belongs_to :chat_room, counter_cache: true, touch: :last_message_at
  belongs_to :sender, class_name: "User"

  # 메시지 타입: text(일반), system(시스템), profile_card(프로필 전송), deal_confirm(거래 확정)
  enum :message_type, {
    text: "text",
    system: "system",
    profile_card: "profile_card",
    contact_card: "contact_card",
    deal_confirm: "deal_confirm"
  }, default: :text

  validates :content, presence: true, length: { maximum: 2000 }

  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }

  after_create_commit :broadcast_message
  after_create_commit :notify_recipient, unless: :system_message?
  after_create_commit :resurrect_hidden_participants

  # 시스템 메시지인지 확인
  def system_message?
    system? || deal_confirm?
  end

  # 일반 텍스트 메시지인지 확인
  def user_message?
    text?
  end

  # 카드 타입 메시지인지 확인
  def card_message?
    profile_card? || contact_card?
  end

  private

  def broadcast_message
    # Turbo Stream 브로드캐스트 (채팅방)
    broadcast_append_to chat_room,
                        target: "messages",
                        partial: "messages/message",
                        locals: { message: self, current_user: sender }

    # 상대방에게 채팅방 목록 업데이트 브로드캐스트
    chat_room.participants.where.not(user_id: sender_id).each do |participant|
      # 채팅 뱃지 업데이트
      broadcast_replace_to "user_#{participant.user_id}_chat_badge",
                           target: "chat_unread_badge",
                           partial: "shared/chat_unread_badge",
                           locals: { count: participant.user.total_unread_messages }
    end
  end

  def notify_recipient
    chat_room.participants.where.not(user_id: sender_id).each do |participant|
      Notification.create(
        recipient: participant.user,
        actor: sender,
        action: "message",
        notifiable: self
      )
    end
  end

  # 채팅방을 나간(숨긴) 참여자가 있으면 다시 보이게 복구
  def resurrect_hidden_participants
    hidden_participants = chat_room.participants.where.not(deleted_at: nil)
    return if hidden_participants.empty?

    # 숨겨진 모든 참여자를 다시 보이게 복구
    hidden_participants.update_all(deleted_at: nil)

    # 복구된 참여자들에게 채팅 목록 업데이트 알림
    hidden_participants.each do |participant|
      broadcast_replace_to "user_#{participant.user_id}_chat_badge",
                           target: "chat_unread_badge",
                           partial: "shared/chat_unread_badge",
                           locals: { count: participant.user.reload.total_unread_messages }
    end
  end
end
