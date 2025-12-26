# 토스페이먼츠 결제 승인 서비스
# 클라이언트에서 결제 완료 후 서버에서 최종 승인 처리
module TossPayments
  class ApproveService < BaseService
    # 금액 불일치 에러 클래스
    class AmountMismatchError < StandardError
      attr_reader :expected_amount, :actual_amount

      def initialize(expected_amount:, actual_amount:)
        @expected_amount = expected_amount
        @actual_amount = actual_amount
        super("금액이 일치하지 않습니다. 예상: #{expected_amount}원, 실제: #{actual_amount}원")
      end
    end

    # 결제 승인 처리
    # @param payment_key [String] 토스페이먼츠에서 발급한 결제 키
    # @param order_id [String] 가맹점에서 생성한 주문 ID (PAY-xxx 형식)
    # @param amount [Integer] 결제 금액
    # @return [Result] 성공 시 결제 정보, 실패 시 에러
    def call(payment_key:, order_id:, amount:)
      validate_params!(payment_key, order_id, amount)

      # 금액 변조 방지: DB에 저장된 주문 금액과 클라이언트에서 받은 금액 비교
      validate_amount!(order_id, amount.to_i)

      Rails.logger.info "[TossPayments::ApproveService] Approving payment: #{order_id}"

      result = post("/payments/confirm", {
        paymentKey: payment_key,
        orderId: order_id,
        amount: amount
      })

      if result.success?
        Rails.logger.info "[TossPayments::ApproveService] Payment approved: #{order_id}"
        update_payment_record(result.data)
      else
        Rails.logger.error "[TossPayments::ApproveService] Payment failed: #{result.error&.message}"
        mark_payment_failed(order_id, result.error)
      end

      result
    rescue AmountMismatchError => e
      Rails.logger.error "[TossPayments::ApproveService] Amount validation failed: #{e.message}"
      mark_payment_failed(order_id, e)
      Result.failure(
        ValidationError.new(
          code: "AMOUNT_MISMATCH",
          message: e.message
        )
      )
    end

    private

    # 파라미터 검증
    def validate_params!(payment_key, order_id, amount)
      raise ArgumentError, "payment_key is required" if payment_key.blank?
      raise ArgumentError, "order_id is required" if order_id.blank?
      raise ArgumentError, "amount must be positive" if amount.to_i <= 0
    end

    # 금액 검증: 클라이언트 금액과 DB 주문 금액 비교
    # 금액 변조 공격 방지를 위한 필수 검증
    def validate_amount!(order_id, client_amount)
      payment = Payment.find_by_toss_order_id(order_id)

      unless payment
        raise ArgumentError, "결제 정보를 찾을 수 없습니다: #{order_id}"
      end

      order = payment.order
      expected_amount = order.amount

      if client_amount != expected_amount
        raise AmountMismatchError.new(
          expected_amount: expected_amount,
          actual_amount: client_amount
        )
      end

      Rails.logger.info "[TossPayments::ApproveService] Amount validated: #{expected_amount}원"
    end

    # 결제 성공 시 Payment 레코드 업데이트
    def update_payment_record(response_data)
      payment = Payment.find_by_toss_order_id(response_data[:orderId])
      return unless payment

      payment.approve!(response_data)
      Rails.logger.info "[TossPayments::ApproveService] Payment record updated: #{payment.id}"
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[TossPayments::ApproveService] Failed to update payment: #{e.message}"
    end

    # 결제 실패 시 Payment 레코드 업데이트
    def mark_payment_failed(order_id, error)
      payment = Payment.find_by_toss_order_id(order_id)
      return unless payment

      payment.mark_as_failed!(
        code: error&.code || "UNKNOWN_ERROR",
        message: error&.message || "결제 승인에 실패했습니다."
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[TossPayments::ApproveService] Failed to mark payment as failed: #{e.message}"
    end
  end
end
