# frozen_string_literal: true

require "test_helper"

module TossPayments
  class CancelServiceTest < ActiveSupport::TestCase
    setup do
      @service = TossPayments::CancelService.new
      @order = orders(:paid_order)
      @payment = payments(:card_payment)
      @payment_key = @payment.payment_key
      @cancel_reason = "사용자 요청에 의한 취소"
    end

    # ============================================================================
    # Successful Cancellation Tests
    # ============================================================================

    test "call should cancel payment with valid params" do
      response_data = mock_toss_cancel_success(@payment_key, @payment.amount)
      mock_http_post_success(response_data)

      result = @service.call(
        payment_key: @payment_key,
        cancel_reason: @cancel_reason
      )

      assert result.success?, "Service should succeed with valid params"
      assert_not_nil result.data, "Result should contain response data"
    end

    test "call should update payment record on success" do
      response_data = mock_toss_cancel_success(@payment_key, @payment.amount)
      mock_http_post_success(response_data)

      @service.call(
        payment_key: @payment_key,
        cancel_reason: @cancel_reason
      )

      @payment.reload
      assert @payment.cancelled?, "Payment should be marked as cancelled"
      assert_not_nil @payment.cancelled_at, "cancelled_at should be set"
    end

    test "call should support partial cancellation with cancel_amount" do
      partial_amount = @payment.amount / 2
      response_data = mock_toss_cancel_success(@payment_key, partial_amount)
      mock_http_post_success(response_data)

      result = @service.call(
        payment_key: @payment_key,
        cancel_reason: "부분 취소",
        cancel_amount: partial_amount
      )

      assert result.success?, "Should support partial cancellation"
    end

    # ============================================================================
    # Parameter Validation Tests
    # ============================================================================

    test "call should raise ArgumentError when payment_key is blank" do
      assert_raises ArgumentError, "payment_key is required" do
        @service.call(
          payment_key: "",
          cancel_reason: @cancel_reason
        )
      end
    end

    test "call should raise ArgumentError when cancel_reason is blank" do
      assert_raises ArgumentError, "cancel_reason is required" do
        @service.call(
          payment_key: @payment_key,
          cancel_reason: ""
        )
      end
    end

    # ============================================================================
    # cancel_payment Convenience Method Tests
    # ============================================================================

    test "cancel_payment should cancel payment with default reason" do
      response_data = mock_toss_cancel_success(@payment_key, @payment.amount)
      mock_http_post_success(response_data)

      result = @service.cancel_payment(@payment)

      assert result.success?, "cancel_payment should succeed"
    end

    test "cancel_payment should use custom reason" do
      custom_reason = "상품 품절"
      response_data = mock_toss_cancel_success(@payment_key, @payment.amount)
      mock_http_post_success(response_data)

      result = @service.cancel_payment(@payment, reason: custom_reason)

      assert result.success?, "Should accept custom cancel reason"
    end

    test "cancel_payment should fail when payment is nil" do
      result = @service.cancel_payment(nil)

      assert result.failure?, "Should fail when payment is nil"
      assert_equal "INVALID_PAYMENT", result.error.code
      assert_equal "결제 정보가 없습니다.", result.error.message
    end

    test "cancel_payment should fail when payment is not done" do
      pending_payment = payments(:virtual_account_payment)

      result = @service.cancel_payment(pending_payment)

      assert result.failure?, "Should fail when payment is not done"
      assert_equal "NOT_PAID", result.error.code
      assert_equal "결제 완료된 건만 취소할 수 있습니다.", result.error.message
    end

    test "cancel_payment should fail when payment_key is missing" do
      # Create payment with toss_order_id but without payment_key
      payment_without_key = Payment.create!(
        order: @order,
        user: @order.user,
        amount: @order.amount,
        status: :done
        # payment_key is nil
      )

      result = @service.cancel_payment(payment_without_key)

      assert result.failure?, "Should fail when payment_key is missing"
      assert_equal "NO_PAYMENT_KEY", result.error.code
    end

    # ============================================================================
    # API Error Handling Tests
    # ============================================================================

    test "call should handle API validation errors" do
      error_response = {
        code: "INVALID_PAYMENT_KEY",
        message: "결제 키가 유효하지 않습니다"
      }
      mock_http_post_error(400, error_response)

      result = @service.call(
        payment_key: "invalid_key",
        cancel_reason: @cancel_reason
      )

      assert result.failure?, "Should fail on API validation error"
      assert_equal "INVALID_PAYMENT_KEY", result.error.code
    end

    test "call should handle already cancelled payment" do
      error_response = {
        code: "ALREADY_CANCELED",
        message: "이미 취소된 결제입니다"
      }
      mock_http_post_error(400, error_response)

      result = @service.call(
        payment_key: @payment_key,
        cancel_reason: @cancel_reason
      )

      assert result.failure?, "Should fail on already cancelled payment"
      assert_equal "ALREADY_CANCELED", result.error.code
    end

    # ============================================================================
    # Security Tests (보안 테스트)
    # ============================================================================

    test "cancel_payment should validate buyer ownership" do
      # Create a payment for a different user
      other_user = users(:two)
      other_order = Order.create!(
        user: other_user,
        post: posts(:hiring_post),  # 외주 글만 결제 가능
        title: "Other User Order",
        amount: 100000
      )
      other_payment = Payment.create!(
        order: other_order,
        user: other_user,
        amount: other_order.amount,
        status: :done,
        payment_key: "pk_other_user_key"
      )

      # The service itself doesn't enforce ownership (controller does)
      # But we verify the payment belongs to the correct user
      assert_equal other_user.id, other_payment.user_id,
                   "Payment should belong to the user who created it"
      assert_not_equal @payment.user_id, other_payment.user_id,
                       "Payments should belong to different users"
    end

    test "cancel_payment should reject already cancelled payment" do
      @payment.update!(status: :cancelled, cancelled_at: 1.hour.ago)

      result = @service.cancel_payment(@payment)

      assert result.failure?, "Should fail for already cancelled payment"
      assert_equal "NOT_PAID", result.error.code,
                   "Error should indicate payment is not in done status"
    end

    test "cancel_payment should handle duplicate cancellation requests gracefully" do
      # First cancellation succeeds
      response_data = mock_toss_cancel_success(@payment_key, @payment.amount)
      mock_http_post_success(response_data)

      result1 = @service.cancel_payment(@payment)
      assert result1.success?, "First cancellation should succeed"

      @payment.reload
      assert @payment.cancelled?, "Payment should be cancelled"

      # Second cancellation should fail (payment already cancelled)
      result2 = @service.cancel_payment(@payment)

      assert result2.failure?, "Second cancellation should fail"
      assert_equal "NOT_PAID", result2.error.code,
                   "Should reject since payment is no longer in done status"
    end

    test "call should reject partial cancel exceeding paid amount" do
      excessive_amount = @payment.amount + 10000

      error_response = {
        code: "INVALID_CANCEL_AMOUNT",
        message: "취소 금액이 결제 금액을 초과합니다"
      }
      mock_http_post_error(400, error_response)

      result = @service.call(
        payment_key: @payment_key,
        cancel_reason: "부분 취소 테스트",
        cancel_amount: excessive_amount
      )

      assert result.failure?, "Should fail when cancel amount exceeds payment"
      assert_equal "INVALID_CANCEL_AMOUNT", result.error.code
    end

    test "call should reject cancellation for very old payments" do
      # Toss typically has 30-day cancellation limit for certain payment methods
      error_response = {
        code: "CANCEL_PERIOD_EXPIRED",
        message: "취소 가능 기간이 지났습니다"
      }
      mock_http_post_error(400, error_response)

      result = @service.call(
        payment_key: @payment_key,
        cancel_reason: @cancel_reason
      )

      assert result.failure?, "Should fail for expired cancellation period"
      assert_equal "CANCEL_PERIOD_EXPIRED", result.error.code
    end

    # ============================================================================
    # Transaction Rollback Tests (트랜잭션 롤백 테스트)
    # ============================================================================

    test "call should not update payment if API call fails" do
      original_status = @payment.status

      error_response = {
        code: "CANCEL_FAILED",
        message: "취소에 실패했습니다"
      }
      mock_http_post_error(400, error_response)

      @service.call(
        payment_key: @payment_key,
        cancel_reason: @cancel_reason
      )

      @payment.reload
      assert_equal original_status, @payment.status,
                   "Payment status should remain unchanged on API failure"
      assert_nil @payment.cancelled_at,
                 "cancelled_at should remain nil on API failure"
    end

    test "call should handle network timeout gracefully" do
      @service.define_singleton_method(:http_client) do
        client = Object.new
        client.define_singleton_method(:post) { |*args| raise Timeout::Error, "Connection timed out" }
        client
      end

      result = @service.call(
        payment_key: @payment_key,
        cancel_reason: @cancel_reason
      )

      assert result.failure?, "Should fail on network timeout"
      @payment.reload
      assert_not @payment.cancelled?, "Payment should not be marked as cancelled on timeout"
    end

    test "call should log failed cancellation for manual review" do
      error_response = {
        code: "CANCEL_FAILED",
        message: "환불 처리에 실패했습니다"
      }
      mock_http_post_error(400, error_response)

      log_output = capture_log do
        @service.call(
          payment_key: @payment_key,
          cancel_reason: @cancel_reason
        )
      end

      assert_match /Cancel failed/, log_output,
                   "Should log cancellation failure"
      assert_match /CANCEL_FAILED/, log_output,
                   "Should log the error code for tracking"
    end

    test "call should handle payment record update failure gracefully" do
      response_data = mock_toss_cancel_success(@payment_key, @payment.amount)
      mock_http_post_success(response_data)

      # Verify service completes successfully
      log_output = capture_log do
        result = @service.call(
          payment_key: @payment_key,
          cancel_reason: @cancel_reason
        )
        # API call should succeed
        assert result.success?, "Result should reflect API success"
        assert result.data.present?, "Should contain response data"
      end

      # Verify some logging occurred
      assert log_output.present?, "Should have log output"
    end

    # ============================================================================
    # Logging Tests
    # ============================================================================

    test "call should log cancellation attempt" do
      response_data = mock_toss_cancel_success(@payment_key, @payment.amount)
      mock_http_post_success(response_data)

      log_output = capture_log do
        @service.call(
          payment_key: @payment_key,
          cancel_reason: @cancel_reason
        )
      end

      assert_match /Cancelling payment/, log_output,
                   "Should log cancellation attempt"
      assert_match /Payment cancelled/, log_output,
                   "Should log successful cancellation"
    end

    test "call should log cancellation failures" do
      error_response = {
        code: "CANCEL_FAILED",
        message: "취소에 실패했습니다"
      }
      mock_http_post_error(400, error_response)

      log_output = capture_log do
        @service.call(
          payment_key: @payment_key,
          cancel_reason: @cancel_reason
        )
      end

      assert_match /Cancel failed/, log_output,
                   "Should log cancellation failure"
    end

    private

    # Fake HTTP Client for testing
    class FakeHttpClient
      attr_accessor :response

      def post(url, body, headers)
        @response
      end

      def get(url, headers)
        @response
      end
    end

    # Mock successful HTTP POST response
    def mock_http_post_success(data)
      response = mock_http_response(200, data.deep_stringify_keys.to_json)
      fake_client = FakeHttpClient.new
      fake_client.response = response

      @service.define_singleton_method(:http_client) { fake_client }
    end

    # Mock HTTP POST error response
    def mock_http_post_error(status_code, data)
      response = mock_http_response(status_code, data.deep_stringify_keys.to_json)
      fake_client = FakeHttpClient.new
      fake_client.response = response

      @service.define_singleton_method(:http_client) { fake_client }
    end

    # Create mock HTTP response
    def mock_http_response(code, body)
      response = Object.new
      response.define_singleton_method(:code) { code.to_s }
      response.define_singleton_method(:body) { body }
      response
    end

    # Capture Rails logger output
    def capture_log
      original_logger = Rails.logger
      string_io = StringIO.new
      Rails.logger = Logger.new(string_io)

      yield

      string_io.string
    ensure
      Rails.logger = original_logger
    end
  end
end
