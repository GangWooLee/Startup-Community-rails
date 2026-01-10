# frozen_string_literal: true

module Payments
  # 토스페이먼츠 웹훅 처리 서비스
  #
  # 처리 이벤트:
  # - PAYMENT_STATUS_CHANGED: 결제 상태 변경
  # - DEPOSIT_CALLBACK: 가상계좌 입금 확인
  #
  # 사용 예:
  #   result = Payments::WebhookHandler.call(payload)
  #   if result.success?
  #     # 처리 완료
  #   else
  #     # 에러 처리
  #   end
  class WebhookHandler
    attr_reader :payload, :event_type

    def self.call(payload)
      new(payload).call
    end

    def initialize(payload)
      @payload = payload
      @event_type = payload[:eventType]
    end

    def call
      Rails.logger.info "[Payments::WebhookHandler] Received: #{event_type}"

      case event_type
      when "PAYMENT_STATUS_CHANGED"
        handle_payment_status_change
      when "DEPOSIT_CALLBACK"
        handle_virtual_account_deposit
      else
        Rails.logger.warn "[Payments::WebhookHandler] Unknown event type: #{event_type}"
      end

      Result.new(success: true)
    rescue StandardError => e
      Rails.logger.error "[Payments::WebhookHandler] Error: #{e.message}"
      Result.new(success: false, error: e.message)
    end

    private

    # 결제 상태 변경 처리
    def handle_payment_status_change
      data = payload[:data]
      payment_key = data[:paymentKey]
      status = data[:status]

      payment = Payment.find_by(payment_key: payment_key)
      return unless payment

      case status
      when "DONE"
        payment.update!(status: :done) unless payment.done?
      when "CANCELED"
        payment.mark_as_cancelled!
      end

      Rails.logger.info "[Payments::WebhookHandler] Payment status changed: #{payment_key} -> #{status}"
    end

    # 가상계좌 입금 확인 처리
    def handle_virtual_account_deposit
      data = payload[:data]
      order_id = data[:orderId]
      status = data[:status]

      payment = Payment.find_by_toss_order_id(order_id)
      return unless payment

      Rails.logger.info "[Payments::WebhookHandler] Virtual account: #{order_id}, status: #{status}"

      case status
      when "DONE"
        if payment.confirm_virtual_account_deposit!(data)
          Rails.logger.info "[Payments::WebhookHandler] Virtual account deposit confirmed: #{order_id}"
        end
      when "CANCELED"
        payment.mark_as_cancelled!
        Rails.logger.info "[Payments::WebhookHandler] Virtual account cancelled: #{order_id}"
      end
    end

    # 결과 객체
    class Result
      attr_reader :error

      def initialize(success:, error: nil)
        @success = success
        @error = error
      end

      def success?
        @success
      end
    end
  end
end
