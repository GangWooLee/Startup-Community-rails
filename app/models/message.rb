class Message < ApplicationRecord
  belongs_to :chat_room, counter_cache: true, touch: :last_message_at
  belongs_to :sender, class_name: "User"

  # 거래 제안 메시지는 주문과 연결될 수 있음
  has_one :order, foreign_key: :offer_message_id, dependent: :nullify

  # 메시지 타입: text(일반), system(시스템), profile_card(프로필 전송), deal_confirm(거래 확정), offer_card(거래 제안)
  enum :message_type, {
    text: "text",
    system: "system",
    profile_card: "profile_card",
    contact_card: "contact_card",
    deal_confirm: "deal_confirm",
    offer_card: "offer_card"
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
    profile_card? || contact_card? || offer_card?
  end

  # 거래 제안 카드 데이터 접근
  # metadata 구조:
  # {
  #   amount: 1000000,
  #   title: "MVP 백엔드 개발",
  #   description: "...",
  #   deadline: "2025-01-26",
  #   refund_policy: "no_refund", # or "partial", "full"
  #   status: "pending"  # pending, paid, completed, cancelled
  # }
  def offer_data
    return nil unless offer_card?
    metadata&.with_indifferent_access
  end

  # 거래 제안 상태 확인 헬퍼
  def offer_pending?
    offer_card? && offer_data&.dig(:status) == "pending"
  end

  def offer_paid?
    offer_card? && offer_data&.dig(:status) == "paid"
  end

  def offer_completed?
    offer_card? && offer_data&.dig(:status) == "completed"
  end

  def offer_cancelled?
    offer_card? && offer_data&.dig(:status) == "cancelled"
  end

  # 거래 제안 상태 업데이트
  def update_offer_status!(new_status)
    return false unless offer_card?
    return false unless %w[pending paid completed cancelled].include?(new_status)

    update!(metadata: (metadata || {}).merge("status" => new_status))
  end

  private

  def broadcast_message
    # chat_room을 reload하여 touch로 업데이트된 last_message_at 반영
    chat_room.reload

    # 각 참여자에게 개별 브로드캐스트 (각자의 관점에 맞게)
    chat_room.participants.each do |participant|
      is_sender = participant.user_id == sender_id

      # 해당 사용자의 채팅방 스트림으로 브로드캐스트
      broadcast_append_to "chat_room_#{chat_room.id}_user_#{participant.user_id}",
                          target: "messages",
                          partial: "messages/message",
                          locals: {
                            message: self,
                            current_user: participant.user,
                            is_read: is_sender ? false : true,  # 보낸 사람: 상대방이 안 읽음, 받는 사람: 읽음 표시 불필요
                            show_profile: true,
                            show_time: true
                          }

      # 채팅 목록 아이템 업데이트 (제자리에서 교체 후 JS로 정렬)
      # replace를 사용하면 DOM 변경이 한 번만 발생하여 화면이 튀지 않음
      broadcast_replace_to "user_#{participant.user_id}_chat_list",
                           target: "chat_room_#{chat_room.id}",
                           partial: "chat_rooms/chat_list_item",
                           locals: { room: chat_room, current_user: participant.user, is_active: is_sender }

      # 상대방에게만 뱃지 업데이트 (보낸 사람은 이미 해당 채팅방에 있으므로 불필요)
      unless is_sender
        # 채팅 뱃지 업데이트 (헤더/네비게이션)
        broadcast_replace_to "user_#{participant.user_id}_chat_badge",
                             target: "chat_unread_badge",
                             partial: "shared/chat_unread_badge",
                             locals: { count: participant.user.total_unread_messages }
      end
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
