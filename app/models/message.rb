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

  # 5초 내 동일 내용 메시지 중복 방지 (IME 이슈로 인한 중복 전송 방지)
  validate :prevent_duplicate_within_timeframe, on: :create, if: :user_message?

  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }

  # ==========================================================================
  # Callbacks - Service Object로 위임
  # ==========================================================================
  # 이전: 5개의 개별 콜백 (순서 의존성 문제)
  # 현재: 1개의 콜백으로 통합, Service에서 순서 보장
  after_create_commit :handle_post_creation

  # ==========================================================================
  # Query Methods
  # ==========================================================================

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

  # ==========================================================================
  # 거래 제안 카드 관련 메서드
  # ==========================================================================

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

  # 5초 내 동일 내용 메시지 중복 방지
  # IME(한글 입력기) 버그로 인한 중복 전송 방지
  def prevent_duplicate_within_timeframe
    return unless content.present? && sender_id.present? && chat_room_id.present?

    recent_duplicate = Message.where(
      chat_room_id: chat_room_id,
      sender_id: sender_id,
      content: content
    ).where("created_at > ?", 5.seconds.ago).exists?

    if recent_duplicate
      errors.add(:content, "최근 5초 내 동일한 메시지가 전송되었습니다")
    end
  end

  # ==========================================================================
  # Post-Creation Handler
  # ==========================================================================
  # 메시지 생성 후 필요한 작업들을 Service로 위임
  # 처리 순서:
  # 1. 발신자 읽음 상태 업데이트
  # 2. 수신자 미읽음 수 증가
  # 3. Turbo Streams 브로드캐스트
  # 4. 알림 생성 (시스템 메시지 제외)
  # 5. 숨긴 참여자 복구
  def handle_post_creation
    Messages::PostCreationService.call(self)
  end
end
