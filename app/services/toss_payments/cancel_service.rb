# 토스페이먼츠 결제 취소 서비스
# 결제 완료된 건에 대해 취소/환불 처리
module TossPayments
  class CancelService < BaseService
    # 결제 취소 처리
    # @param payment_key [String] 토스페이먼츠에서 발급한 결제 키
    # @param cancel_reason [String] 취소 사유
    # @param cancel_amount [Integer, nil] 부분 취소 금액 (nil이면 전액 취소)
    # @return [Result] 성공 시 취소 정보, 실패 시 에러
    def call(payment_key:, cancel_reason:, cancel_amount: nil)
      validate_params!(payment_key, cancel_reason)

      Rails.logger.info "[TossPayments::CancelService] Cancelling payment: #{payment_key}"

      body = {
        cancelReason: cancel_reason
      }
      body[:cancelAmount] = cancel_amount if cancel_amount.present?

      result = post("/payments/#{payment_key}/cancel", body)

      if result.success?
        Rails.logger.info "[TossPayments::CancelService] Payment cancelled: #{payment_key}"
        update_payment_record(payment_key, result.data)
      else
        Rails.logger.error "[TossPayments::CancelService] Cancel failed: #{result.error&.message}"
      end

      result
    end

    # Payment 레코드로 취소 처리 (편의 메서드)
    def cancel_payment(payment, reason: "사용자 요청에 의한 취소")
      return Result.failure(ValidationError.new(code: "INVALID_PAYMENT", message: "결제 정보가 없습니다.")) unless payment
      return Result.failure(ValidationError.new(code: "NOT_PAID", message: "결제 완료된 건만 취소할 수 있습니다.")) unless payment.done?
      return Result.failure(ValidationError.new(code: "NO_PAYMENT_KEY", message: "결제 키가 없습니다.")) if payment.payment_key.blank?

      call(
        payment_key: payment.payment_key,
        cancel_reason: reason
      )
    end

    private

    # 파라미터 검증
    def validate_params!(payment_key, cancel_reason)
      raise ArgumentError, "payment_key is required" if payment_key.blank?
      raise ArgumentError, "cancel_reason is required" if cancel_reason.blank?
    end

    # 결제 취소 시 Payment 레코드 업데이트
    def update_payment_record(payment_key, response_data)
      payment = Payment.find_by(payment_key: payment_key)
      return unless payment

      payment.mark_as_cancelled!(response_data)
      Rails.logger.info "[TossPayments::CancelService] Payment record updated: #{payment.id}"
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[TossPayments::CancelService] Failed to update payment: #{e.message}"
    end
  end
end
