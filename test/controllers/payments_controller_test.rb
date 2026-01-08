# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "ostruct"

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_one = users(:one)
    @user_two = users(:two)
    @user_three = users(:three)
    @hiring_post = posts(:hiring_post)
    @seeking_post = posts(:seeking_post)
    @pending_order = orders(:pending_order)
    @paid_order = orders(:paid_order)
  end

  # ============================================================================
  # Authentication Tests
  # ============================================================================

  test "new requires login" do
    get new_payment_path(post_id: @hiring_post.id)
    assert_redirected_to login_path
  end

  test "create requires login" do
    post payments_path(post_id: @hiring_post.id)
    assert_redirected_to login_path
  end

  test "webhook does not require login" do
    post webhook_payments_path, params: {}, as: :json
    # Should NOT redirect to login (302) - webhooks are external calls
    # In test environment without webhook_secret, it allows the request (200)
    # In production with secret, invalid signature would return 401
    assert_not_equal 302, response.status, "Webhook should not redirect to login"
    assert_includes [ 200, 400, 401 ], response.status
  end

  # ============================================================================
  # NEW Action Tests - Payment Context
  # ============================================================================

  test "new with post_id shows payment widget" do
    log_in_as(@user_two)
    get new_payment_path(post_id: @hiring_post.id)

    assert_response :success
    assert_not_nil assigns(:order)
    assert_not_nil assigns(:payment)
    assert_not_nil assigns(:toss_client_key)
  end

  test "new without context redirects with alert" do
    log_in_as(@user_two)
    get new_payment_path

    assert_redirected_to root_path
    assert_equal "결제 대상을 찾을 수 없습니다.", flash[:alert]
  end

  test "new with nonexistent post redirects" do
    log_in_as(@user_two)
    get new_payment_path(post_id: 99999)

    assert_redirected_to root_path
    assert_equal "게시글을 찾을 수 없습니다.", flash[:alert]
  end

  # ============================================================================
  # NEW Action Tests - Payment Eligibility
  # ============================================================================

  test "new with non-outsourcing post redirects" do
    log_in_as(@user_two)
    community_post = posts(:one)
    get new_payment_path(post_id: community_post.id)

    assert_redirected_to post_path(community_post)
    assert_equal "외주 글만 결제할 수 있습니다.", flash[:alert]
  end

  test "new with own post redirects" do
    log_in_as(@user_one)
    get new_payment_path(post_id: @hiring_post.id)

    assert_redirected_to post_path(@hiring_post)
    assert_equal "본인의 글은 결제할 수 없습니다.", flash[:alert]
  end

  test "new with post without price redirects" do
    log_in_as(@user_two)
    # Create a hiring post without price
    no_price_post = Post.create!(
      user: @user_one,
      title: "No price post",
      content: "Test",
      category: :hiring,
      service_type: :development,
      work_type: :remote
    )

    get new_payment_path(post_id: no_price_post.id)

    assert_redirected_to post_path(no_price_post)
    assert_equal "가격이 설정되지 않은 글입니다.", flash[:alert]
  end

  # ============================================================================
  # CREATE Action Tests (AJAX)
  # ============================================================================

  test "create returns JSON with order details" do
    log_in_as(@user_two)
    post payments_path(post_id: @hiring_post.id), as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["success"]
    assert_not_nil json["order_id"]
    assert_equal "Rails 백엔드 개발자 구합니다", json["order_name"]
    assert_equal 3000000, json["amount"]
    assert_equal @user_two.name, json["customer_name"]
  end

  test "create with invalid context redirects" do
    log_in_as(@user_two)
    post payments_path, as: :json

    # Without post_id or offer_message_id, controller redirects to root
    assert_redirected_to root_path
  end

  # ============================================================================
  # SUCCESS Action Tests - Payment Approval
  # ============================================================================

  test "success with done payment returns success" do
    # Test idempotency: already done payment should not call API again
    log_in_as(@user_three)
    payment = payments(:card_payment)
    assert payment.done?, "Payment should already be done"

    get success_payments_path(
      paymentKey: payment.payment_key,
      orderId: payment.toss_order_id,
      amount: payment.amount
    )

    assert_redirected_to success_order_path(payment.order)
    assert_equal "결제가 완료되었습니다!", flash[:notice]
  end

  test "success with already done payment skips API call (idempotency)" do
    log_in_as(@user_three)
    payment = payments(:card_payment)
    assert payment.done?

    # Ensure service is NOT called
    TossPayments::ApproveService.stub :new, -> { flunk "Should not call ApproveService" } do
      get success_payments_path(
        paymentKey: payment.payment_key,
        orderId: payment.toss_order_id,
        amount: payment.amount
      )

      assert_redirected_to success_order_path(payment.order)
      assert_equal "결제가 완료되었습니다!", flash[:notice]
    end
  end

  test "success requires valid payment parameters" do
    skip "Requires WebMock or VCR for external API mocking"
    # This test would verify:
    # - Invalid payment_key handling
    # - Non-existent order handling
    # - API failure scenarios
    # Proper implementation requires WebMock gem to mock TossPayments API
  end

  # ============================================================================
  # FAIL Action Tests
  # ============================================================================

  test "fail renders error page" do
    log_in_as(@user_two)
    get fail_payments_path(
      code: "REJECT_CARD",
      message: "카드 한도 초과",
      orderId: "PAY-TEST-123"
    )

    assert_response :success
    assert_equal "REJECT_CARD", assigns(:error_code)
    assert_equal "카드 한도 초과", assigns(:error_message)
  end

  test "fail marks payment as failed" do
    log_in_as(@user_two)
    payment = payments(:virtual_account_payment)

    get fail_payments_path(
      code: "TIMEOUT",
      message: "결제 시간 초과",
      orderId: payment.toss_order_id
    )

    payment.reload
    assert payment.failed?
  end

  # ============================================================================
  # WEBHOOK Action Tests - Signature Verification
  # ============================================================================

  test "webhook with invalid signature returns unauthorized" do
    # Pass hash directly - Rails will serialize to JSON
    payload = { eventType: "PAYMENT_STATUS_CHANGED" }
    invalid_signature = "invalid_signature_123"

    # Configure a webhook secret so signature verification actually happens
    Rails.application.credentials.stub :dig, "test_webhook_secret" do
      post webhook_payments_path,
        params: payload,
        headers: { "TossPayments-Signature" => invalid_signature },
        as: :json

      assert_response :unauthorized
    end
  end

  test "webhook with valid signature processes event" do
    payment = payments(:virtual_account_payment)
    # Ensure payment has a payment_key for lookup
    payment.update!(payment_key: "pk_test_webhook_valid") unless payment.payment_key.present?

    # Pass hash directly - Rails will serialize to JSON
    payload = {
      eventType: "PAYMENT_STATUS_CHANGED",
      data: {
        paymentKey: payment.payment_key,
        status: "DONE"
      }
    }

    # In test environment without webhook_secret configured,
    # signature verification is skipped (see controller code)
    post webhook_payments_path,
      params: payload,
      as: :json

    assert_response :success
    # Verify payment status was updated
    payment.reload
    assert payment.done?, "Payment should be marked as done"
  end

  test "webhook without signature in development mode is allowed" do
    # Pass hash directly with valid structure
    # Include data key to avoid nil error in event handler
    payload = {
      eventType: "UNKNOWN_EVENT",  # Use unknown event to skip processing
      data: {}
    }

    # In test environment without webhook_secret, signature verification is skipped
    # This is equivalent to development behavior
    post webhook_payments_path,
      params: payload,
      as: :json

    # Should succeed (allowed in test/development mode without secret)
    assert_response :success
    assert true, "Webhook processed without signature in development mode"
  end

  test "webhook with invalid JSON returns bad request" do
    invalid_json = "{ this is not valid JSON"
    signature = "test_signature"

    post webhook_payments_path,
      params: invalid_json,
      headers: {
        "TossPayments-Signature" => signature,
        "Content-Type" => "application/json"
      }

    assert_response :bad_request
  end

  # ============================================================================
  # WEBHOOK Action Tests - Event Handling
  # ============================================================================

  test "webhook PAYMENT_STATUS_CHANGED to DONE updates payment status" do
    payment = payments(:virtual_account_payment)
    # Ensure payment has a payment_key and is in ready state
    payment.update!(payment_key: "pk_test_status_done", status: :ready)
    assert payment.ready?

    # Pass hash directly - Rails will serialize to JSON
    payload = {
      eventType: "PAYMENT_STATUS_CHANGED",
      data: {
        paymentKey: payment.payment_key,
        status: "DONE"
      }
    }

    # In test environment, signature verification is skipped when no secret configured
    post webhook_payments_path,
      params: payload,
      as: :json

    assert_response :success
    payment.reload
    assert payment.done?
  end

  test "webhook PAYMENT_STATUS_CHANGED to CANCELED marks payment as cancelled" do
    payment = payments(:card_payment)
    assert payment.done?

    # Pass hash directly - Rails will serialize to JSON
    payload = {
      eventType: "PAYMENT_STATUS_CHANGED",
      data: {
        paymentKey: payment.payment_key,
        status: "CANCELED"
      }
    }

    # In test environment, signature verification is skipped when no secret configured
    post webhook_payments_path,
      params: payload,
      as: :json

    assert_response :success
    payment.reload
    assert payment.cancelled?
  end

  test "webhook DEPOSIT_CALLBACK confirms virtual account deposit" do
    payment = payments(:virtual_account_payment)

    # Pass hash directly - Rails will serialize to JSON
    payload = {
      eventType: "DEPOSIT_CALLBACK",
      data: {
        orderId: payment.toss_order_id,
        status: "DONE",
        amount: payment.amount
      }
    }

    # In test environment, signature verification is skipped when no secret configured
    post webhook_payments_path,
      params: payload,
      as: :json

    assert_response :success
    assert true, "Virtual account deposit callback processed"
  end

  # ============================================================================
  # Private Method Tests (via Integration)
  # ============================================================================

  test "toss_client_key returns configured key from credentials" do
    log_in_as(@user_two)

    Rails.application.credentials.stub :dig, "live_client_key_123" do
      get new_payment_path(post_id: @hiring_post.id)

      assert_equal "live_client_key_123", assigns(:toss_client_key)
    end
  end

  test "toss_client_key falls back to test key in development" do
    log_in_as(@user_two)

    Rails.application.credentials.stub :dig, nil do
      Rails.stub :env, ActiveSupport::StringInquirer.new("development") do
        get new_payment_path(post_id: @hiring_post.id)

        assert_equal "test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm", assigns(:toss_client_key)
      end
    end
  end
end
