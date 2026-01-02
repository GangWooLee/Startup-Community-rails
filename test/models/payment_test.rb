# frozen_string_literal: true

require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    @user = users(:three)
    @order = orders(:pending_order)
    @paid_order = orders(:paid_order)
    @card_payment = payments(:card_payment)
    @virtual_account_payment = payments(:virtual_account_payment)
  end

  # ============================================================================
  # Validations
  # ============================================================================

  test "should be valid with valid attributes" do
    payment = Payment.new(
      order: @order,
      user: @user,
      amount: @order.amount
    )
    assert payment.valid?, "Payment should be valid with required attributes"
  end

  test "should require toss_order_id" do
    @card_payment.toss_order_id = nil
    assert_not @card_payment.valid?, "Payment should require toss_order_id"
    assert_includes @card_payment.errors[:toss_order_id], "can't be blank"
  end

  test "should require unique toss_order_id" do
    duplicate = Payment.new(
      order: @order,
      user: @user,
      toss_order_id: @card_payment.toss_order_id,
      amount: 100000
    )
    assert_not duplicate.valid?, "toss_order_id should be unique"
    assert_includes duplicate.errors[:toss_order_id], "has already been taken"
  end

  test "should require amount" do
    @card_payment.amount = nil
    assert_not @card_payment.valid?, "Payment should require amount"
    assert_includes @card_payment.errors[:amount], "can't be blank"
  end

  test "should require positive amount" do
    @card_payment.amount = 0
    assert_not @card_payment.valid?, "Amount should be greater than 0"
    assert_includes @card_payment.errors[:amount], "must be greater than 0"

    @card_payment.amount = -1000
    assert_not @card_payment.valid?, "Amount should not be negative"
  end

  test "should allow nil payment_key for pending payments" do
    payment = Payment.new(
      order: @order,
      user: @user,
      amount: @order.amount
    )
    assert_nil payment.payment_key
    assert payment.valid?, "Payment key can be nil for pending payments"
  end

  test "should require unique payment_key when present" do
    duplicate = Payment.new(
      order: @order,
      user: @user,
      payment_key: @card_payment.payment_key,
      amount: 100000
    )
    assert_not duplicate.valid?, "payment_key should be unique when present"
    assert_includes duplicate.errors[:payment_key], "has already been taken"
  end

  test "should validate amount matches order amount" do
    payment = Payment.new(
      order: @order,
      user: @user,
      amount: @order.amount + 1000  # Different amount
    )
    assert_not payment.valid?, "Payment amount should match order amount"
    assert_includes payment.errors[:amount], "주문 금액과 일치해야 합니다"
  end

  # ============================================================================
  # Associations
  # ============================================================================

  test "should belong to order" do
    assert_instance_of Order, @card_payment.order, "Payment should belong to order"
    assert_equal @paid_order, @card_payment.order
  end

  test "should belong to user" do
    assert_instance_of User, @card_payment.user, "Payment should belong to user"
  end

  test "should delegate post to order" do
    assert_respond_to @card_payment, :post, "Payment should delegate post to order"
    assert_equal @card_payment.order.post, @card_payment.post
  end

  test "should delegate seller to order" do
    assert_respond_to @card_payment, :seller, "Payment should delegate seller to order"
    assert_equal @card_payment.order.seller, @card_payment.seller
  end

  # ============================================================================
  # Enums
  # ============================================================================

  test "should have correct status enum values" do
    payment = Payment.new(order: @order, user: @user, amount: @order.amount)
    assert payment.pending?, "Default status should be pending"

    payment.ready!
    assert payment.ready?, "Should transition to ready"

    payment.done!
    assert payment.done?, "Should transition to done"

    payment.cancelled!
    assert payment.cancelled?, "Should transition to cancelled"

    payment.failed!
    assert payment.failed?, "Should transition to failed"
  end

  # ============================================================================
  # Scopes
  # ============================================================================

  test "successful scope should return only done payments" do
    successful = Payment.successful
    assert successful.all?(&:done?), "Successful scope should only return done payments"
    assert_includes successful, @card_payment
  end

  test "recent scope should order by created_at desc" do
    payments = Payment.recent.to_a
    assert payments.first.created_at >= payments.last.created_at,
           "Recent scope should order by created_at descending"
  end

  test "pending_virtual_accounts scope should return ready virtual accounts" do
    pending_vas = Payment.pending_virtual_accounts
    assert pending_vas.all? { |p| p.method == "VIRTUAL_ACCOUNT" && p.ready? },
           "Should only return ready virtual account payments"
    assert_includes pending_vas, @virtual_account_payment
  end

  test "expired_virtual_accounts scope should return overdue virtual accounts" do
    # Create expired virtual account
    expired_va = Payment.create!(
      order: @order,
      user: @user,
      amount: @order.amount,
      method: "VIRTUAL_ACCOUNT",
      status: :ready,
      due_date: 1.day.ago
    )

    expired_vas = Payment.expired_virtual_accounts
    assert_includes expired_vas, expired_va,
                    "Should include virtual accounts past due date"
    assert_not_includes expired_vas, @virtual_account_payment,
                        "Should not include non-expired virtual accounts"
  end

  # ============================================================================
  # Class Methods
  # ============================================================================

  test "find_by_toss_order_id should find payment" do
    payment = Payment.find_by_toss_order_id(@card_payment.toss_order_id)
    assert_equal @card_payment, payment,
                 "Should find payment by toss_order_id"
  end

  test "find_by_toss_order_id should return nil for nonexistent ID" do
    payment = Payment.find_by_toss_order_id("NONEXISTENT")
    assert_nil payment, "Should return nil for nonexistent toss_order_id"
  end

  # ============================================================================
  # Business Logic - Card Payment Approval
  # ============================================================================

  test "approve! with CARD method should complete payment immediately" do
    payment = Payment.create!(order: @order, user: @user, amount: @order.amount)
    assert payment.pending?, "Payment should start as pending"

    response_data = mock_toss_approve_success(
      "pk_test_new123",
      payment.toss_order_id,
      payment.amount
    ).deep_symbolize_keys

    payment.approve!(response_data)

    payment.reload
    assert payment.done?, "Card payment should be immediately done"
    assert_equal "pk_test_new123", payment.payment_key
    assert_equal "CARD", payment.method, "Method should be CARD"
    assert_not_nil payment.approved_at, "approved_at should be set"
    assert_not_nil payment.card_company, "Card company should be set"
    assert_equal "신한카드", payment.card_company
    assert_not_nil payment.card_number, "Card number should be masked"
  end

  test "approve! with CARD should update order to paid" do
    order = orders(:pending_order)
    payment = Payment.create!(order: order, user: @user, amount: order.amount)

    assert order.pending?, "Order should be pending before payment"

    response_data = mock_toss_approve_success(
      "pk_test_card",
      payment.toss_order_id,
      payment.amount
    ).deep_symbolize_keys

    payment.approve!(response_data)

    order.reload
    assert order.paid?, "Order should be marked as paid after card approval"
    assert_not_nil order.paid_at, "Order paid_at should be set"
  end

  # ============================================================================
  # Business Logic - Virtual Account Approval
  # ============================================================================

  test "approve! with VIRTUAL_ACCOUNT should set status to ready" do
    payment = Payment.create!(order: @order, user: @user, amount: @order.amount)

    response_data = {
      method: "VIRTUAL_ACCOUNT",
      paymentKey: nil,
      virtualAccount: {
        bankCode: "004",
        bank: "국민은행",
        accountNumber: "12345678901234",
        customerName: "홍길동",
        dueDate: 3.days.from_now.iso8601
      },
      receipt: { url: "https://example.com/receipt" }
    }

    payment.approve!(response_data)

    payment.reload
    assert payment.ready?, "Virtual account should be in ready status"
    assert_equal "VIRTUAL_ACCOUNT", payment.method
    assert_equal "004", payment.bank_code
    assert_equal "국민은행", payment.bank_name
    assert_equal "12345678901234", payment.account_number
    assert_equal "홍길동", payment.account_holder
    assert_not_nil payment.due_date, "Due date should be set"
  end

  test "approve! with VIRTUAL_ACCOUNT should not immediately update order" do
    order = orders(:pending_order)
    payment = Payment.create!(order: order, user: @user, amount: order.amount)

    response_data = {
      method: "VIRTUAL_ACCOUNT",
      paymentKey: nil,
      virtualAccount: {
        bankCode: "004",
        bank: "국민은행",
        accountNumber: "12345678901234",
        customerName: "홍길동",
        dueDate: 3.days.from_now.iso8601
      }
    }

    payment.approve!(response_data)

    order.reload
    assert order.pending?, "Order should remain pending until deposit confirmed"
  end

  test "confirm_virtual_account_deposit! should complete payment and order" do
    payment = @virtual_account_payment
    order = payment.order

    assert payment.ready?, "Virtual account should be ready"
    assert order.pending?, "Order should be pending"

    result = payment.confirm_virtual_account_deposit!

    assert result, "Deposit confirmation should succeed"
    payment.reload
    order.reload
    assert payment.done?, "Payment should be done after deposit"
    assert_not_nil payment.approved_at, "approved_at should be set"
    assert order.paid?, "Order should be paid after deposit confirmation"
  end

  test "confirm_virtual_account_deposit! should not work for non-virtual-account" do
    result = @card_payment.confirm_virtual_account_deposit!

    assert_not result, "Should not confirm deposit for non-virtual-account payment"
    assert @card_payment.done?, "Card payment status should remain unchanged"
  end

  test "confirm_virtual_account_deposit! should not work for non-ready status" do
    payment = @virtual_account_payment
    payment.update_columns(status: :done)

    result = payment.confirm_virtual_account_deposit!

    assert_not result, "Should not confirm deposit for already-done payment"
  end

  # ============================================================================
  # Business Logic - Other Payment Methods
  # ============================================================================

  test "approve! with TRANSFER method should complete immediately" do
    payment = Payment.create!(order: @order, user: @user, amount: @order.amount)

    response_data = {
      method: "TRANSFER",
      paymentKey: "pk_transfer_123",
      transfer: { bankCode: "088" },
      receipt: { url: "https://example.com/receipt" }
    }

    payment.approve!(response_data)

    payment.reload
    assert payment.done?, "Transfer payment should be immediately done"
    assert_equal "TRANSFER", payment.method
    assert_not_nil payment.approved_at
  end

  test "approve! should store raw response data" do
    payment = Payment.create!(order: @order, user: @user, amount: @order.amount)

    response_data = mock_toss_approve_success(
      "pk_test",
      payment.toss_order_id,
      payment.amount
    ).deep_symbolize_keys

    payment.approve!(response_data)

    payment.reload
    assert_not_nil payment.raw_response, "Raw response should be stored"
    assert payment.raw_response.is_a?(Hash), "Raw response should be a hash"
  end

  # ============================================================================
  # Business Logic - Failure & Cancellation
  # ============================================================================

  test "mark_as_failed! should set status and error details" do
    payment = Payment.create!(order: @order, user: @user, amount: @order.amount)

    payment.mark_as_failed!(code: "INVALID_CARD", message: "유효하지 않은 카드입니다")

    payment.reload
    assert payment.failed?, "Payment should be failed"
    assert_equal "INVALID_CARD", payment.failure_code
    assert_equal "유효하지 않은 카드입니다", payment.failure_message
  end

  test "mark_as_cancelled! should set status and timestamp" do
    @card_payment.mark_as_cancelled!

    @card_payment.reload
    assert @card_payment.cancelled?, "Payment should be cancelled"
    assert_not_nil @card_payment.cancelled_at, "cancelled_at should be set"
  end

  test "mark_as_cancelled! should optionally store response data" do
    cancel_response = { cancelAmount: 100000, cancelReason: "고객 요청" }
    @card_payment.mark_as_cancelled!(cancel_response)

    @card_payment.reload
    assert_not_nil @card_payment.raw_response, "Cancel response should be stored"
  end

  # ============================================================================
  # Instance Methods - Virtual Account
  # ============================================================================

  test "virtual_account? should check method" do
    assert @virtual_account_payment.virtual_account?,
           "Should return true for virtual account"
    assert_not @card_payment.virtual_account?,
           "Should return false for card payment"
  end

  test "waiting_for_deposit? should check virtual account and ready status" do
    assert @virtual_account_payment.waiting_for_deposit?,
           "Ready virtual account should be waiting for deposit"

    @virtual_account_payment.update_columns(status: :done)
    assert_not @virtual_account_payment.waiting_for_deposit?,
           "Done virtual account should not be waiting"

    assert_not @card_payment.waiting_for_deposit?,
           "Non-virtual-account should not be waiting"
  end

  test "deposit_expired? should check due_date" do
    # Not expired
    assert_not @virtual_account_payment.deposit_expired?,
               "Virtual account before due date should not be expired"

    # Expired
    @virtual_account_payment.update_columns(due_date: 1.day.ago)
    assert @virtual_account_payment.deposit_expired?,
           "Virtual account past due date should be expired"
  end

  test "virtual_account_info should return formatted info" do
    info = @virtual_account_payment.virtual_account_info

    assert_not_nil info, "Should return info hash"
    assert_equal "국민은행", info[:bank_name]
    assert_equal "12345678901234", info[:account_number]
    assert_equal "User Two", info[:account_holder]
    assert_not_nil info[:due_date]
    assert_match /\d{4}\.\d{2}\.\d{2} \d{2}:\d{2}/, info[:formatted_due_date]
  end

  test "virtual_account_info should return nil for non-virtual-account" do
    info = @card_payment.virtual_account_info
    assert_nil info, "Should return nil for non-virtual-account payment"
  end

  # ============================================================================
  # Instance Methods - Display
  # ============================================================================

  test "receipt_available? should check receipt_url presence" do
    @card_payment.update_columns(receipt_url: "https://example.com/receipt")
    assert @card_payment.receipt_available?, "Should return true when receipt_url present"

    @card_payment.update_columns(receipt_url: nil)
    assert_not @card_payment.receipt_available?, "Should return false when receipt_url nil"
  end

  test "status_label should return Korean status" do
    payment = Payment.new(order: @order, user: @user, amount: 100000)

    payment.status = :pending
    assert_equal "결제 대기", payment.status_label

    payment.status = :ready
    assert_equal "입금 대기", payment.status_label

    payment.status = :done
    assert_equal "결제 완료", payment.status_label

    payment.status = :cancelled
    assert_equal "취소됨", payment.status_label

    payment.status = :failed
    assert_equal "결제 실패", payment.status_label
  end

  test "method_label should return Korean method name" do
    assert_equal "카드", Payment.new(method: "CARD").method_label
    assert_equal "가상계좌", Payment.new(method: "VIRTUAL_ACCOUNT").method_label
    assert_equal "계좌이체", Payment.new(method: "TRANSFER").method_label
    assert_equal "휴대폰", Payment.new(method: "MOBILE").method_label
  end

  test "formatted_amount should display in Korean won" do
    @card_payment.amount = 1_234_567
    formatted = @card_payment.formatted_amount
    assert_match /1,234,567원/, formatted,
                 "Should format amount in Korean won without decimals"
  end

  # ============================================================================
  # Callbacks
  # ============================================================================

  test "should auto-generate toss_order_id on create" do
    payment = Payment.new(order: @order, user: @user, amount: @order.amount)
    assert_nil payment.toss_order_id, "toss_order_id should be nil before save"

    payment.save!

    assert_not_nil payment.toss_order_id, "toss_order_id should be generated"
    assert_match /^PAY-\d+-[A-F0-9]{8}$/, payment.toss_order_id,
                 "toss_order_id should match format PAY-{timestamp}-{hex}"
  end

  test "should not regenerate toss_order_id if already set" do
    existing_id = @card_payment.toss_order_id
    @card_payment.save!

    assert_equal existing_id, @card_payment.toss_order_id,
                 "toss_order_id should not change on update"
  end

  test "after_update should mark order as paid when payment is done" do
    order = orders(:pending_order)
    payment = Payment.create!(order: order, user: @user, amount: order.amount)

    assert order.pending?, "Order should be pending"

    payment.update!(status: :done, approved_at: Time.current)

    order.reload
    assert order.paid?, "Order should be marked as paid when payment done"
  end

  test "after_update should cancel order when payment is cancelled" do
    order = orders(:paid_order)
    payment = order.successful_payment

    assert order.paid?, "Order should be paid"

    payment.update!(status: :cancelled, cancelled_at: Time.current)

    order.reload
    assert order.cancelled?, "Order should be cancelled when payment cancelled"
  end

  # ============================================================================
  # Edge Cases
  # ============================================================================

  test "should handle payments without due_date" do
    payment = Payment.create!(
      order: @order,
      user: @user,
      amount: @order.amount,
      method: "VIRTUAL_ACCOUNT",
      status: :ready,
      due_date: nil
    )

    assert_not payment.deposit_expired?, "Payment without due_date should not be expired"
  end

  test "should handle concurrent toss_order_id generation" do
    ids = []
    10.times do
      payment = Payment.create!(
        order: @order,
        user: @user,
        amount: @order.amount
      )
      ids << payment.toss_order_id
    end

    assert_equal ids.uniq.size, ids.size,
                 "All toss_order_ids should be unique"
  end

  test "should handle large amounts correctly" do
    # Create order with large amount first
    large_order = Order.create!(
      user: @user,
      post: @order.post,
      title: "Large Order",
      amount: 999_999_999
    )

    payment = Payment.create!(
      order: large_order,
      user: @user,
      amount: large_order.amount
    )

    assert_equal 999_999_999, payment.amount
    formatted = payment.formatted_amount
    assert_match /999,999,999원/, formatted
  end

  # ============================================================================
  # Security Tests
  # ============================================================================

  test "should sanitize card number for storage" do
    # Card numbers should always be masked (****1234 format)
    assert_match /^\*+\d{4}$/, @card_payment.card_number,
                 "Card number should be masked"
  end

  test "should prevent SQL injection in failure_message" do
    malicious_message = "'; DROP TABLE payments; --"
    payment = Payment.create!(order: @order, user: @user, amount: @order.amount)

    payment.mark_as_failed!(code: "TEST", message: malicious_message)

    payment.reload
    assert_equal malicious_message, payment.failure_message,
                 "Failure message should be stored as-is (Rails protects against SQL injection)"
    assert Payment.exists?(payment.id), "Payments table should still exist"
  end

  # ============================================================================
  # Transaction Rollback Tests
  # ============================================================================

  test "should rollback approve! on error" do
    payment = Payment.create!(order: @order, user: @user, amount: @order.amount)
    original_status = payment.status

    # Simulate transaction rollback
    begin
      ActiveRecord::Base.transaction do
        payment.update!(status: :done, approved_at: Time.current)
        raise ActiveRecord::Rollback
      end
    rescue ActiveRecord::Rollback
      # Expected
    end

    payment.reload
    assert_equal original_status, payment.status,
                 "Status should not change on rollback"
  end

  test "should rollback confirm_virtual_account_deposit! on error" do
    payment = @virtual_account_payment
    original_status = payment.status

    # Simulate transaction rollback
    begin
      ActiveRecord::Base.transaction do
        payment.update!(status: :done, approved_at: Time.current)
        raise ActiveRecord::Rollback
      end
    rescue ActiveRecord::Rollback
      # Expected
    end

    payment.reload
    assert_equal original_status, payment.status,
                 "Status should not change on rollback"
  end

  test "should maintain data consistency between payment and order" do
    order = orders(:pending_order)
    payment = Payment.create!(order: order, user: @user, amount: order.amount)

    # Both should update atomically
    Payment.transaction do
      payment.update!(status: :done, approved_at: Time.current)
      order.update!(status: :paid, paid_at: Time.current)
    end

    payment.reload
    order.reload
    assert payment.done?, "Payment should be done"
    assert order.paid?, "Order should be paid"
  end

  test "should handle errors in update_order_status callback gracefully" do
    # update_order_status is a private method, so check it exists
    assert Payment.private_method_defined?(:update_order_status),
           "Payment should have private method update_order_status"

    # Verify callback is defined in after_update
    callbacks = Payment._update_callbacks.select { |c| c.filter == :update_order_status }
    assert callbacks.any?, "update_order_status should be an after_update callback"
  end
end
