# 주문 모델 - 비즈니스 거래 정보
# 1. 구매자가 외주 글(Post)에 대해 결제할 때 생성됨
# 2. 채팅에서 거래 제안(offer_card)을 통해 생성됨
class Order < ApplicationRecord
  include OrderStateable  # 상태 변경/확인/표시 로직

  # 플랫폼 수수료율 (10%)
  PLATFORM_FEE_RATE = 0.10

  # 관계
  belongs_to :user                                      # 구매자
  belongs_to :post, optional: true                      # 외주 글 (선택적)
  belongs_to :seller, class_name: "User"                # 판매자
  belongs_to :chat_room, optional: true                 # 채팅방 (채팅 기반 주문용)
  belongs_to :offer_message, class_name: "Message", optional: true  # 거래 제안 메시지
  has_many :payments, dependent: :destroy
  has_one :successful_payment, -> { where(status: :done) }, class_name: "Payment"

  # Enum (거래 확정까지 지원하는 확장된 상태)
  enum :status, {
    pending: 0,       # 결제 대기
    paid: 1,          # 결제 완료 (에스크로 보관 중)
    in_progress: 2,   # 작업 진행 중 (paid와 동일, UI 구분용)
    completed: 3,     # 거래 확정 (정산 완료)
    cancelled: 4,     # 취소됨
    refunded: 5,      # 환불됨
    disputed: 6       # 분쟁 중 (향후 확장)
  }, default: :pending

  enum :order_type, {
    outsourcing: 0,  # 외주 결제 (현재)
    premium: 1,      # 프리미엄 기능 (향후)
    promotion: 2     # 광고/홍보 (향후)
  }, default: :outsourcing

  # 검증
  validates :order_number, presence: true, uniqueness: true
  validates :title, presence: true, length: { maximum: 100 }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validate :must_have_context, on: :create
  validate :post_must_be_outsourcing, on: :create, if: -> { post.present? }
  validate :cannot_order_own_post, on: :create, if: -> { post.present? }
  validate :cannot_order_from_self_in_chat, on: :create, if: -> { chat_room.present? }

  # 콜백
  before_validation :generate_order_number, on: :create
  before_validation :set_seller, on: :create

  # 스코프
  scope :recent, -> { order(created_at: :desc) }
  scope :for_buyer, ->(user) { where(user: user) }
  scope :for_seller, ->(user) { where(seller: user) }
  scope :active, -> { where.not(status: [ :cancelled, :refunded ]) }

  # === 정산 관련 ===

  # 플랫폼 수수료 계산
  def platform_fee
    (amount * PLATFORM_FEE_RATE).to_i
  end

  # 판매자 정산 금액 (수수료 제외)
  def settlement_amount
    amount - platform_fee
  end

  # 정산 금액 포맷팅
  def formatted_settlement_amount
    ActiveSupport::NumberHelper.number_to_currency(settlement_amount, unit: "원", format: "%n%u", precision: 0)
  end

  # 플랫폼 수수료 포맷팅
  def formatted_platform_fee
    ActiveSupport::NumberHelper.number_to_currency(platform_fee, unit: "원", format: "%n%u", precision: 0)
  end

  # 채팅 기반 주문인지 확인
  def chat_based?
    chat_room_id.present?
  end

  # Post 기반 주문인지 확인
  def post_based?
    post_id.present?
  end

  # 금액 포맷팅 (원화는 소수점 없음)
  def formatted_amount
    ActiveSupport::NumberHelper.number_to_currency(amount, unit: "원", format: "%n%u", precision: 0)
  end

  private

  # 주문 번호 생성 (ORD-YYYYMMDD-XXXXXX)
  def generate_order_number
    return if order_number.present?

    loop do
      self.order_number = "ORD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.alphanumeric(6).upcase}"
      break unless Order.exists?(order_number: order_number)
    end
  end

  # 판매자 자동 설정
  def set_seller
    return if seller_id.present?

    if post.present?
      self.seller = post.user
    elsif chat_room.present? && user.present?
      # 채팅 기반: 상대방이 판매자
      self.seller = chat_room.other_participant(user)
    end
  end

  # Post 또는 ChatRoom 중 하나는 필수
  def must_have_context
    if post_id.blank? && chat_room_id.blank?
      errors.add(:base, "주문은 게시글 또는 채팅방 컨텍스트가 필요합니다")
    end
  end

  # 외주 글만 주문 가능 (Post 기반 주문)
  def post_must_be_outsourcing
    unless post.outsourcing?
      errors.add(:post, "외주 글(구인/구직)만 결제할 수 있습니다")
    end
  end

  # 본인 글 주문 불가 (Post 기반)
  def cannot_order_own_post
    if user_id == post.user_id
      errors.add(:base, "본인의 글은 결제할 수 없습니다")
    end
  end

  # 채팅에서 자기 자신에게 주문 불가
  def cannot_order_from_self_in_chat
    other_user = chat_room.other_participant(user)
    if other_user.nil? || user_id == seller_id
      errors.add(:base, "본인에게는 결제할 수 없습니다")
    end
  end
end
