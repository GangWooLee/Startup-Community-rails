# frozen_string_literal: true

require "test_helper"

module Payments
  class WebhookHandlerTest < ActiveSupport::TestCase
    setup do
      @payment = payments(:card_payment)
      @virtual_payment = payments(:virtual_account_payment)
    end

    # ============================================================================
    # PAYMENT_STATUS_CHANGED Event Tests
    # ============================================================================

    test "handles PAYMENT_STATUS_CHANGED event with DONE status" do
      # 결제가 완료 상태가 아닌 경우를 테스트하기 위해 ready 상태로 변경
      @payment.update!(status: :ready)

      payload = {
        eventType: "PAYMENT_STATUS_CHANGED",
        data: {
          paymentKey: @payment.payment_key,
          status: "DONE"
        }
      }

      result = Payments::WebhookHandler.call(payload)

      assert result.success?
      @payment.reload
      assert @payment.done?
    end

    test "handles PAYMENT_STATUS_CHANGED event with CANCELED status" do
      payload = {
        eventType: "PAYMENT_STATUS_CHANGED",
        data: {
          paymentKey: @payment.payment_key,
          status: "CANCELED"
        }
      }

      result = Payments::WebhookHandler.call(payload)

      assert result.success?
      @payment.reload
      assert @payment.cancelled?
    end

    test "ignores unknown payment_key in PAYMENT_STATUS_CHANGED" do
      payload = {
        eventType: "PAYMENT_STATUS_CHANGED",
        data: {
          paymentKey: "unknown_payment_key",
          status: "DONE"
        }
      }

      result = Payments::WebhookHandler.call(payload)

      assert result.success?
    end

    test "does not change already DONE payment" do
      assert @payment.done?

      payload = {
        eventType: "PAYMENT_STATUS_CHANGED",
        data: {
          paymentKey: @payment.payment_key,
          status: "DONE"
        }
      }

      assert_no_changes -> { @payment.reload.updated_at } do
        result = Payments::WebhookHandler.call(payload)
        assert result.success?
      end
    end

    # ============================================================================
    # DEPOSIT_CALLBACK Event Tests
    # ============================================================================

    test "handles DEPOSIT_CALLBACK event with DONE status" do
      assert @virtual_payment.ready?

      payload = {
        eventType: "DEPOSIT_CALLBACK",
        data: {
          orderId: @virtual_payment.toss_order_id,
          status: "DONE",
          approvedAt: Time.current.iso8601
        }
      }

      result = Payments::WebhookHandler.call(payload)

      assert result.success?
    end

    test "handles DEPOSIT_CALLBACK event with CANCELED status" do
      payload = {
        eventType: "DEPOSIT_CALLBACK",
        data: {
          orderId: @virtual_payment.toss_order_id,
          status: "CANCELED"
        }
      }

      result = Payments::WebhookHandler.call(payload)

      assert result.success?
      @virtual_payment.reload
      assert @virtual_payment.cancelled?
    end

    test "ignores unknown orderId in DEPOSIT_CALLBACK" do
      payload = {
        eventType: "DEPOSIT_CALLBACK",
        data: {
          orderId: "UNKNOWN-ORDER-ID",
          status: "DONE"
        }
      }

      result = Payments::WebhookHandler.call(payload)

      assert result.success?
    end

    # ============================================================================
    # Unknown Event Type Tests
    # ============================================================================

    test "handles unknown event type gracefully" do
      payload = {
        eventType: "UNKNOWN_EVENT_TYPE",
        data: {}
      }

      result = Payments::WebhookHandler.call(payload)

      assert result.success?
    end

    # ============================================================================
    # Error Handling Tests
    # ============================================================================

    test "returns failure result on unexpected error" do
      # 존재하지 않는 payment_key로 테스트하되, 내부 로직에서 예외 발생 시뮬레이션
      # handler 인스턴스의 메서드를 오버라이드
      handler = Payments::WebhookHandler.new({
        eventType: "PAYMENT_STATUS_CHANGED",
        data: {
          paymentKey: "test_key",
          status: "DONE"
        }
      })

      # private 메서드 오버라이드로 예외 발생
      def handler.handle_payment_status_change
        raise StandardError, "Database error"
      end

      result = handler.call

      assert_not result.success?
      assert_equal "Database error", result.error
    end

    test "Result object responds to success?" do
      result = Payments::WebhookHandler::Result.new(success: true)
      assert result.success?

      result = Payments::WebhookHandler::Result.new(success: false, error: "test error")
      assert_not result.success?
      assert_equal "test error", result.error
    end
  end
end
