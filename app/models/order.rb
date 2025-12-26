# 주문 모델 - 비즈니스 거래 정보
# 구매자가 외주 글(Post)에 대해 결제할 때 생성됨
class Order < ApplicationRecord
  # 관계
  belongs_to :user                                      # 구매자
  belongs_to :post
  belongs_to :seller, class_name: "User"                # 판매자 (post.user)
  has_many :payments, dependent: :destroy
  has_one :successful_payment, -> { where(status: :done) }, class_name: "Payment"

  # Enum
  enum :status, {
    pending: 0,     # 결제 대기
    paid: 1,        # 결제 완료
    cancelled: 2,   # 취소됨
    refunded: 3     # 환불됨
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
  validate :post_must_be_outsourcing, on: :create
  validate :cannot_order_own_post, on: :create

  # 콜백
  before_validation :generate_order_number, on: :create
  before_validation :set_seller_from_post, on: :create

  # 스코프
  scope :recent, -> { order(created_at: :desc) }
  scope :for_buyer, ->(user) { where(user: user) }
  scope :for_seller, ->(user) { where(seller: user) }

  # 결제 완료 처리
  def mark_as_paid!(payment)
    update!(
      status: :paid,
      paid_at: Time.current
    )
  end

  # 취소 처리
  def mark_as_cancelled!
    update!(
      status: :cancelled,
      cancelled_at: Time.current
    )
  end

  # 환불 처리
  def mark_as_refunded!
    update!(
      status: :refunded,
      refunded_at: Time.current
    )
  end

  # 결제 가능 여부
  def can_pay?
    pending?
  end

  # 취소 가능 여부
  def can_cancel?
    paid? && created_at > 7.days.ago  # 7일 이내만 취소 가능
  end

  # 상태 표시 (한글)
  def status_label
    case status
    when "pending" then "결제 대기"
    when "paid" then "결제 완료"
    when "cancelled" then "취소됨"
    when "refunded" then "환불됨"
    else status
    end
  end

  # 금액 포맷팅
  def formatted_amount
    ActiveSupport::NumberHelper.number_to_currency(amount, unit: "원", format: "%n%u")
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
  def set_seller_from_post
    self.seller ||= post&.user
  end

  # 외주 글만 주문 가능
  def post_must_be_outsourcing
    return unless post

    unless post.outsourcing?
      errors.add(:post, "외주 글(구인/구직)만 결제할 수 있습니다")
    end
  end

  # 본인 글 주문 불가
  def cannot_order_own_post
    return unless user && post

    if user_id == post.user_id
      errors.add(:base, "본인의 글은 결제할 수 없습니다")
    end
  end
end
