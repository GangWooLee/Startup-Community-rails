# 결제 모델 - 토스페이먼츠 결제 상세 정보
# Order에 대한 실제 결제 트랜잭션 기록
class Payment < ApplicationRecord
  # 관계
  belongs_to :order
  belongs_to :user

  # 위임
  delegate :post, :seller, to: :order

  # Enum (토스페이먼츠 상태와 동일)
  enum :status, {
    pending: 0,      # 초기 상태
    ready: 1,        # 가상계좌 발급 완료 (입금 대기)
    done: 2,         # 결제 완료
    cancelled: 3,    # 결제 취소
    failed: 4        # 결제 실패
  }, default: :pending

  # 검증
  validates :toss_order_id, presence: true, uniqueness: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_key, uniqueness: true, allow_nil: true
  validate :amount_matches_order

  # 콜백
  before_validation :generate_toss_order_id, on: :create
  after_update :update_order_status, if: :saved_change_to_status?

  # 스코프
  scope :successful, -> { where(status: :done) }
  scope :recent, -> { order(created_at: :desc) }
  scope :pending_virtual_accounts, -> { where(method: "VIRTUAL_ACCOUNT", status: :ready) }
  scope :expired_virtual_accounts, -> { pending_virtual_accounts.where("due_date < ?", Time.current) }

  # 토스 주문 ID로 검색
  def self.find_by_toss_order_id(toss_order_id)
    find_by(toss_order_id: toss_order_id)
  end

  # 결제 승인 처리 (트랜잭션으로 데이터 일관성 보장)
  def approve!(response_data)
    payment_method = response_data[:method]

    update_attrs = {
      payment_key: response_data[:paymentKey],
      method: payment_method,
      method_detail: extract_method_detail(response_data),
      receipt_url: response_data.dig(:receipt, :url),
      raw_response: response_data
    }

    transaction do
      case payment_method
      when "CARD"
        # 카드 결제: 즉시 완료
        update_attrs.merge!(
          status: :done,
          card_company: response_data.dig(:card, :company),
          card_number: response_data.dig(:card, :number),
          card_type: response_data.dig(:card, :cardType),
          approved_at: Time.current
        )
        update!(update_attrs)
        order.mark_as_paid!(self)

      when "VIRTUAL_ACCOUNT"
        # 가상계좌: 입금 대기 상태
        va_data = response_data[:virtualAccount] || {}
        update_attrs.merge!(
          status: :ready,
          bank_code: va_data[:bankCode],
          bank_name: va_data[:bank],
          account_number: va_data[:accountNumber],
          account_holder: va_data[:customerName],
          due_date: va_data[:dueDate].present? ? Time.zone.parse(va_data[:dueDate]) : nil
        )
        update!(update_attrs)
        # 가상계좌는 웹훅으로 입금 확인 후 주문 완료 처리

      else
        # 계좌이체, 휴대폰 등: 즉시 완료
        update_attrs.merge!(
          status: :done,
          approved_at: Time.current
        )
        update!(update_attrs)
        order.mark_as_paid!(self)
      end
    end
  end

  # 가상계좌 입금 확인 처리 (웹훅에서 호출, 트랜잭션 적용)
  def confirm_virtual_account_deposit!(response_data = nil)
    return false unless virtual_account? && ready?

    transaction do
      update!(
        status: :done,
        approved_at: Time.current,
        raw_response: response_data || raw_response
      )

      order.mark_as_paid!(self)
    end
    true
  end

  # 결제 실패 처리
  def mark_as_failed!(code:, message:)
    update!(
      status: :failed,
      failure_code: code,
      failure_message: message
    )
  end

  # 결제 취소 처리
  def mark_as_cancelled!(response_data = nil)
    update!(
      status: :cancelled,
      cancelled_at: Time.current,
      raw_response: response_data || raw_response
    )
  end

  # 영수증 URL 존재 여부
  def receipt_available?
    receipt_url.present?
  end

  # 가상계좌 여부
  def virtual_account?
    method == "VIRTUAL_ACCOUNT"
  end

  # 가상계좌 입금 대기 중 여부
  def waiting_for_deposit?
    virtual_account? && ready?
  end

  # 가상계좌 입금 기한 초과 여부
  def deposit_expired?
    virtual_account? && due_date.present? && due_date < Time.current
  end

  # 가상계좌 정보 포맷팅
  def virtual_account_info
    return nil unless virtual_account?

    {
      bank_name: bank_name,
      account_number: account_number,
      account_holder: account_holder,
      due_date: due_date,
      formatted_due_date: due_date&.strftime("%Y.%m.%d %H:%M")
    }
  end

  # 상태 표시 (한글)
  def status_label
    case status
    when "pending" then "결제 대기"
    when "ready" then "입금 대기"
    when "done" then "결제 완료"
    when "cancelled" then "취소됨"
    when "failed" then "결제 실패"
    else status
    end
  end

  # 결제 수단 표시 (한글)
  def method_label
    case method
    when "CARD" then "카드"
    when "VIRTUAL_ACCOUNT" then "가상계좌"
    when "TRANSFER" then "계좌이체"
    when "MOBILE" then "휴대폰"
    when "CULTURE_GIFT_CERTIFICATE" then "문화상품권"
    when "GAME_GIFT_CERTIFICATE" then "게임문화상품권"
    when "BOOK_GIFT_CERTIFICATE" then "도서문화상품권"
    else method
    end
  end

  # 금액 포맷팅
  def formatted_amount
    ActiveSupport::NumberHelper.number_to_currency(amount, unit: "원", format: "%n%u")
  end

  private

  # 토스 주문 ID 생성 (PAY-{timestamp}-{random})
  def generate_toss_order_id
    return if toss_order_id.present?

    self.toss_order_id = "PAY-#{Time.current.to_i}-#{SecureRandom.hex(4).upcase}"
  end

  # 금액이 주문 금액과 일치하는지 검증
  def amount_matches_order
    return unless order && amount

    if amount != order.amount
      errors.add(:amount, "주문 금액과 일치해야 합니다")
    end
  end

  # 상태 변경 시 주문 상태 업데이트
  def update_order_status
    case status
    when "done"
      order.mark_as_paid!(self)
    when "cancelled"
      order.mark_as_cancelled! if order.paid?
    end
  end

  # 결제 수단 상세 정보 추출
  def extract_method_detail(data)
    case data[:method]
    when "CARD"
      data.dig(:card, :company)
    when "VIRTUAL_ACCOUNT"
      data.dig(:virtualAccount, :bankCode)
    when "TRANSFER"
      data.dig(:transfer, :bankCode)
    else
      nil
    end
  end
end
