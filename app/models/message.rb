class Message < ApplicationRecord
  belongs_to :chat_room, counter_cache: true, touch: :last_message_at
  belongs_to :sender, class_name: "User"

  # 거래 제안 메시지는 주문과 연결될 수 있음
  has_one :order, foreign_key: :offer_message_id, dependent: :nullify

  # 채팅 이미지 첨부 (1장만 허용)
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 200, 200 ]
    attachable.variant :preview, resize_to_limit: [ 400, 400 ]
  end

  # 메시지 타입: text(일반), system(시스템), profile_card(프로필 전송), deal_confirm(거래 확정), offer_card(거래 제안)
  enum :message_type, {
    text: "text",
    system: "system",
    profile_card: "profile_card",
    contact_card: "contact_card",
    deal_confirm: "deal_confirm",
    offer_card: "offer_card"
  }, default: :text

  # 이미지 파일 검증 (보안)
  MAX_IMAGE_SIZE = 5.megabytes
  ALLOWED_IMAGE_TYPES = [ "image/jpeg", "image/png", "image/gif", "image/webp" ].freeze

  validates :content, length: { maximum: 2000 }
  validates :image,
    content_type: { in: ALLOWED_IMAGE_TYPES, message: "는 JPEG, PNG, GIF, WebP만 허용됩니다" },
    size: { less_than: MAX_IMAGE_SIZE, message: "는 5MB 이하만 허용됩니다" },
    if: -> { image.attached? }

  # content 또는 image 중 하나는 필수 (일반 텍스트/이미지 메시지의 경우)
  validate :content_or_image_present, if: :user_message?

  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }

  # 순서 중요! mark_sender_as_read가 먼저 실행되어야 broadcast 시점에 읽음 상태가 반영됨
  after_create_commit :mark_sender_as_read
  after_create_commit :increment_recipient_unread_count
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

  # content 또는 image 중 하나는 필수
  def content_or_image_present
    if content.blank? && !image.attached?
      errors.add(:base, "메시지 내용 또는 이미지가 필요합니다")
    end
  end

  # 메시지 전송 시 발신자의 읽음 상태를 먼저 업데이트
  # broadcast_message보다 먼저 실행되어야 함
  def mark_sender_as_read
    participant = chat_room.participants.find_by(user_id: sender_id)
    # update_columns로 callback/validation 없이 직접 업데이트 (성능 최적화)
    participant&.update_columns(last_read_at: Time.current, unread_count: 0)
  end

  # 수신자들의 unread_count 컬럼 증가 (캐시 컬럼 업데이트)
  def increment_recipient_unread_count
    chat_room.participants
             .where.not(user_id: sender_id)
             .update_all("unread_count = unread_count + 1")
  end

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
  # BUG FIX: 복구 시 실제 안읽은 메시지 수 재계산 (deleted 상태에서 받은 메시지 반영)
  def resurrect_hidden_participants
    hidden_participants = chat_room.participants.where.not(deleted_at: nil)
    return if hidden_participants.empty?

    # 각 참여자별로 실제 안읽은 메시지 수 계산 후 복구
    hidden_participants.each do |participant|
      # deleted 상태에서 받은 메시지 포함하여 실제 unread_count 계산
      actual_unread = chat_room.messages
                               .where.not(sender_id: participant.user_id)
                               .where("created_at > COALESCE(?, '1970-01-01')", participant.last_read_at)
                               .count
      participant.update!(deleted_at: nil, unread_count: actual_unread)
    end

    # 복구된 참여자들에게 채팅 목록 업데이트 알림
    hidden_participants.reload.each do |participant|
      broadcast_replace_to "user_#{participant.user_id}_chat_badge",
                           target: "chat_unread_badge",
                           partial: "shared/chat_unread_badge",
                           locals: { count: participant.user.reload.total_unread_messages }
    end
  end
end
