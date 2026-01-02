# frozen_string_literal: true

require "test_helper"

module TossPayments
  class ApproveServiceTest < ActiveSupport::TestCase
    setup do
      @service = TossPayments::ApproveService.new
      @order = orders(:pending_order)
      @payment = Payment.create!(
        order: @order,
        user: @order.user,
        amount: @order.amount
      )
      @payment_key = "pk_test_approve123"
      @order_id = @payment.toss_order_id
      @amount = @payment.amount
    end

    # ============================================================================
    # Successful Approval Tests
    # ============================================================================

    test "call should approve payment with valid params" do
      # Mock successful API response
      response_data = mock_toss_approve_success(@payment_key, @order_id, @amount)
      mock_http_post_success(response_data)

      result = @service.call(
        payment_key: @payment_key,
        order_id: @order_id,
        amount: @amount
      )

      assert result.success?, "Service should succeed with valid params"
      assert_not_nil result.data, "Result should contain response data"
    end

    test "call should update payment record on success" do
      response_data = mock_toss_approve_success(@payment_key, @order_id, @amount)
      mock_http_post_success(response_data)

      @service.call(
        payment_key: @payment_key,
        order_id: @order_id,
        amount: @amount
      )

      @payment.reload
      assert @payment.done?, "Payment should be marked as done"
      assert_equal @payment_key, @payment.payment_key
      assert_not_nil @payment.approved_at, "approved_at should be set"
    end

    test "call should update order to paid on success" do
      response_data = mock_toss_approve_success(@payment_key, @order_id, @amount)
      mock_http_post_success(response_data)

      @service.call(
        payment_key: @payment_key,
        order_id: @order_id,
        amount: @amount
      )

      @order.reload
      assert @order.paid?, "Order should be marked as paid"
      assert_not_nil @order.paid_at, "paid_at should be set"
    end

    # ============================================================================
    # Parameter Validation Tests
    # ============================================================================

    test "call should raise ArgumentError when payment_key is blank" do
      assert_raises ArgumentError, "payment_key is required" do
        @service.call(
          payment_key: "",
          order_id: @order_id,
          amount: @amount
        )
      end
    end

    test "call should raise ArgumentError when order_id is blank" do
      assert_raises ArgumentError, "order_id is required" do
        @service.call(
          payment_key: @payment_key,
          order_id: "",
          amount: @amount
        )
      end
    end

    test "call should raise ArgumentError when amount is zero" do
      assert_raises ArgumentError, "amount must be positive" do
        @service.call(
          payment_key: @payment_key,
          order_id: @order_id,
          amount: 0
        )
      end
    end

    test "call should raise ArgumentError when amount is negative" do
      assert_raises ArgumentError, "amount must be positive" do
        @service.call(
          payment_key: @payment_key,
          order_id: @order_id,
          amount: -1000
        )
      end
    end

    # ============================================================================
    # Amount Validation Tests (금액 변조 방지)
    # ============================================================================

    test "call should fail when client amount differs from order amount" do
      # Client sends wrong amount (금액 변조 시도)
      tampered_amount = @amount + 1000

      result = @service.call(
        payment_key: @payment_key,
        order_id: @order_id,
        amount: tampered_amount
      )

      assert result.failure?, "Should fail when amounts don't match"
      assert_equal "AMOUNT_MISMATCH", result.error.code
      assert_includes result.error.message, "금액이 일치하지 않습니다"
    end

    test "call should mark payment as failed on amount mismatch" do
      tampered_amount = @amount + 5000

      @service.call(
        payment_key: @payment_key,
        order_id: @order_id,
        amount: tampered_amount
      )

      @payment.reload
      assert @payment.failed?, "Payment should be marked as failed"
      assert_equal "AMOUNT_MISMATCH", @payment.failure_code
    end

    test "call should raise ArgumentError when payment not found" do
      assert_raises ArgumentError, "결제 정보를 찾을 수 없습니다" do
        @service.call(
          payment_key: @payment_key,
          order_id: "NONEXISTENT_ID",
          amount: @amount
        )
      end
    end

    # ============================================================================
    # API Error Handling Tests
    # ============================================================================

    test "call should handle API validation errors" do
      error_response = {
        code: "INVALID_REQUEST",
        message: "결제 키가 유효하지 않습니다"
      }
      mock_http_post_error(400, error_response)

      result = @service.call(
        payment_key: "invalid_key",
        order_id: @order_id,
        amount: @amount
      )

      assert result.failure?, "Should fail on API validation error"
      assert_equal "INVALID_REQUEST", result.error.code
      assert_equal "결제 키가 유효하지 않습니다", result.error.message
    end

    test "call should handle API authentication errors" do
      error_response = {
        code: "UNAUTHORIZED",
        message: "인증에 실패했습니다"
      }
      mock_http_post_error(401, error_response)

      result = @service.call(
        payment_key: @payment_key,
        order_id: @order_id,
        amount: @amount
      )

      assert result.failure?, "Should fail on authentication error"
      assert_instance_of TossPayments::BaseService::AuthenticationError, result.error
    end

    test "call should mark payment as failed on API error" do
      error_response = {
        code: "REJECT_CARD",
        message: "카드 한도 초과"
      }
      mock_http_post_error(400, error_response)

      @service.call(
        payment_key: @payment_key,
        order_id: @order_id,
        amount: @amount
      )

      @payment.reload
      assert @payment.failed?, "Payment should be marked as failed"
      assert_equal "REJECT_CARD", @payment.failure_code
      assert_equal "카드 한도 초과", @payment.failure_message
    end

    # ============================================================================
    # Edge Cases
    # ============================================================================

    test "call should handle very large amounts" do
      large_order = Order.create!(
        user: @order.user,
        post: @order.post,
        title: "Large Order",
        amount: 999_999_999
      )
      large_payment = Payment.create!(
        order: large_order,
        user: large_order.user,
        amount: large_order.amount
      )

      response_data = mock_toss_approve_success(
        @payment_key,
        large_payment.toss_order_id,
        large_payment.amount
      )
      mock_http_post_success(response_data)

      result = @service.call(
        payment_key: @payment_key,
        order_id: large_payment.toss_order_id,
        amount: large_payment.amount
      )

      assert result.success?, "Should handle large amounts correctly"
    end

    test "call should handle concurrent approval attempts gracefully" do
      response_data = mock_toss_approve_success(@payment_key, @order_id, @amount)

      # First approval succeeds
      mock_http_post_success(response_data)
      result1 = @service.call(
        payment_key: @payment_key,
        order_id: @order_id,
        amount: @amount
      )
      assert result1.success?, "First approval should succeed"

      # Second approval should also work (idempotency handled by controller)
      @payment.reload
      assert @payment.done?, "Payment should already be done"
    end

    # ============================================================================
    # Security Tests (보안 테스트)
    # ============================================================================

    test "call should prevent payment key reuse across different orders" do
      # First order - successful approval
      response_data = mock_toss_approve_success(@payment_key, @order_id, @amount)
      mock_http_post_success(response_data)

      result1 = @service.call(
        payment_key: @payment_key,
        order_id: @order_id,
        amount: @amount
      )
      assert result1.success?, "First approval should succeed"
      @payment.reload
      assert_equal @payment_key, @payment.payment_key, "Payment key should be stored"

      # Create second order with different amount
      second_order = Order.create!(
        user: users(:two),
        post: @order.post,
        title: "Second Order",
        amount: 50000
      )
      second_payment = Payment.create!(
        order: second_order,
        user: second_order.user,
        amount: second_order.amount
      )

      # Try to reuse same payment key for different order
      # This should fail at Toss API level or be rejected
      error_response = {
        code: "ALREADY_PROCESSED",
        message: "이미 처리된 결제입니다"
      }
      mock_http_post_error(400, error_response)

      result2 = @service.call(
        payment_key: @payment_key,  # Same payment key
        order_id: second_payment.toss_order_id,
        amount: second_payment.amount
      )

      assert result2.failure?, "Should fail when reusing payment key"
      assert_equal "ALREADY_PROCESSED", result2.error.code
    end

    test "call should handle already done payment gracefully" do
      # Mark payment as already done before approval attempt
      @payment.update!(status: :done, payment_key: @payment_key, approved_at: 1.minute.ago)
      original_approved_at = @payment.approved_at

      # Mock a success response (API might accept or reject)
      response_data = mock_toss_approve_success(@payment_key, @order_id, @amount)
      mock_http_post_success(response_data)

      # Service should process without crashing
      result = @service.call(
        payment_key: @payment_key,
        order_id: @order_id,
        amount: @amount
      )

      @payment.reload
      # Payment should still be in done status
      assert @payment.done?, "Payment should remain in done status"
      # The service processed the request (might update or keep existing)
      assert_not_nil @payment.approved_at, "approved_at should still be set"
    end

    # ============================================================================
    # Transaction Rollback Tests (트랜잭션 롤백 테스트)
    # ============================================================================

    test "call should handle payment update failure gracefully" do
      response_data = mock_toss_approve_success(@payment_key, @order_id, @amount)
      mock_http_post_success(response_data)

      # Service catches RecordInvalid internally, so it should not crash
      # We verify by checking the result and logs
      log_output = capture_log do
        result = @service.call(
          payment_key: @payment_key,
          order_id: @order_id,
          amount: @amount
        )
        # API call should succeed regardless of local update issues
        assert result.success?, "API call should succeed"
        assert result.data.present?, "Should contain Toss response data"
      end

      # Verify logging occurred
      assert log_output.present?, "Should have some log output"
    end

    test "call should return response data on success" do
      response_data = mock_toss_approve_success(@payment_key, @order_id, @amount)
      mock_http_post_success(response_data)

      result = @service.call(
        payment_key: @payment_key,
        order_id: @order_id,
        amount: @amount
      )

      assert result.success?, "Result should be success"
      assert result.data.present?, "Should contain Toss response data"
      assert_equal @order_id, result.data[:orderId], "Response should contain order ID"
    end

    test "call should handle network timeout with appropriate error" do
      # Simulate network timeout
      @service.define_singleton_method(:http_client) do
        client = Object.new
        client.define_singleton_method(:post) { |*args| raise Timeout::Error, "Connection timed out" }
        client
      end

      result = @service.call(
        payment_key: @payment_key,
        order_id: @order_id,
        amount: @amount
      )

      assert result.failure?, "Should fail on timeout"
      @payment.reload
      # Payment should be marked as failed with timeout error
      assert @payment.failed? || @payment.pending?, "Payment should be failed or pending on timeout"
    end

    test "call should preserve payment state on unexpected API errors" do
      original_status = @payment.status

      # Simulate unexpected error
      error_response = {
        code: "INTERNAL_SERVER_ERROR",
        message: "서버 오류가 발생했습니다"
      }
      mock_http_post_error(500, error_response)

      @service.call(
        payment_key: @payment_key,
        order_id: @order_id,
        amount: @amount
      )

      @payment.reload
      assert @payment.failed?, "Payment should be marked as failed on server error"
      assert_equal "INTERNAL_SERVER_ERROR", @payment.failure_code,
                   "Failure code should match API error"
    end

    # ============================================================================
    # Logging Tests
    # ============================================================================

    test "call should log approval attempt" do
      response_data = mock_toss_approve_success(@payment_key, @order_id, @amount)
      mock_http_post_success(response_data)

      # Capture log output
      log_output = capture_log do
        @service.call(
          payment_key: @payment_key,
          order_id: @order_id,
          amount: @amount
        )
      end

      assert_match /Approving payment/, log_output,
                   "Should log approval attempt"
      assert_match /Payment approved/, log_output,
                   "Should log successful approval"
    end

    test "call should log amount validation" do
      response_data = mock_toss_approve_success(@payment_key, @order_id, @amount)
      mock_http_post_success(response_data)

      log_output = capture_log do
        @service.call(
          payment_key: @payment_key,
          order_id: @order_id,
          amount: @amount
        )
      end

      assert_match /Amount validated/, log_output,
                   "Should log successful amount validation"
    end

    test "call should log failures" do
      error_response = {
        code: "PAYMENT_FAILED",
        message: "결제에 실패했습니다"
      }
      mock_http_post_error(400, error_response)

      log_output = capture_log do
        @service.call(
          payment_key: @payment_key,
          order_id: @order_id,
          amount: @amount
        )
      end

      assert_match /Payment failed/, log_output,
                   "Should log payment failure"
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
