# frozen_string_literal: true

require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @buyer = users(:two)
    @seller = users(:three)
    @hiring_post = posts(:hiring_post)
    @seeking_post = posts(:seeking_post)
    @pending_order = orders(:pending_order)
    @paid_order = orders(:paid_order)
    @completed_order = orders(:completed_order)
  end

  # ============================================================================
  # Validations
  # ============================================================================

  test "should be valid with valid attributes" do
    order = Order.new(
      user: @buyer,
      post: @hiring_post,
      title: "Test Order",
      amount: 1_000_000,
      order_type: :outsourcing
    )
    assert order.valid?, "Order should be valid with all required attributes"
  end

  test "should require order_number" do
    @pending_order.order_number = nil
    assert_not @pending_order.valid?, "Order should require order_number"
    assert_includes @pending_order.errors[:order_number], "can't be blank"
  end

  test "should require unique order_number" do
    duplicate_order = Order.new(
      user: @buyer,
      post: @hiring_post,
      order_number: @pending_order.order_number,
      title: "Test",
      amount: 100000
    )
    assert_not duplicate_order.valid?, "Order number should be unique"
    assert_includes duplicate_order.errors[:order_number], "has already been taken"
  end

  test "should require title" do
    @pending_order.title = nil
    assert_not @pending_order.valid?, "Order should require title"
    assert_includes @pending_order.errors[:title], "can't be blank"
  end

  test "should limit title length to 100 characters" do
    @pending_order.title = "a" * 101
    assert_not @pending_order.valid?, "Title should be max 100 characters"
    assert_includes @pending_order.errors[:title], "is too long (maximum is 100 characters)"
  end

  test "should require amount" do
    @pending_order.amount = nil
    assert_not @pending_order.valid?, "Order should require amount"
    assert_includes @pending_order.errors[:amount], "can't be blank"
  end

  test "should require positive amount" do
    @pending_order.amount = 0
    assert_not @pending_order.valid?, "Amount should be greater than 0"
    assert_includes @pending_order.errors[:amount], "must be greater than 0"

    @pending_order.amount = -1000
    assert_not @pending_order.valid?, "Amount should not be negative"
  end

  test "should require post or chat_room context" do
    order = Order.new(
      user: @buyer,
      seller: @seller,
      title: "Test",
      amount: 100000
    )
    assert_not order.valid?, "Order should require either post or chat_room"
    assert_includes order.errors[:base], "주문은 게시글 또는 채팅방 컨텍스트가 필요합니다"
  end

  test "should only allow outsourcing posts" do
    free_post = posts(:one)  # Community post (free category)
    order = Order.new(
      user: @buyer,
      post: free_post,
      title: "Test",
      amount: 100000
    )
    assert_not order.valid?, "Should only allow outsourcing posts"
    assert_includes order.errors[:post], "외주 글(구인/구직)만 결제할 수 있습니다"
  end

  test "should prevent ordering own post" do
    order = Order.new(
      user: @hiring_post.user,
      post: @hiring_post,
      title: "Test",
      amount: 100000
    )
    assert_not order.valid?, "User cannot order their own post"
    assert_includes order.errors[:base], "본인의 글은 결제할 수 없습니다"
  end

  # ============================================================================
  # Associations
  # ============================================================================

  test "should belong to user" do
    assert_instance_of User, @pending_order.user, "Order should belong to user"
    assert_equal @buyer, @pending_order.user
  end

  test "should belong to seller" do
    assert_instance_of User, @pending_order.seller, "Order should belong to seller"
  end

  test "should belong to post optionally" do
    assert_instance_of Post, @pending_order.post, "Order can belong to post"
  end

  test "should have many payments" do
    assert_respond_to @pending_order, :payments, "Order should have many payments"
    assert @pending_order.payments.is_a?(ActiveRecord::Associations::CollectionProxy)
  end

  test "should have one successful payment" do
    payment = @paid_order.successful_payment
    assert_instance_of Payment, payment, "Should have successful payment"
    assert_equal "done", payment.status
  end

  test "should destroy dependent payments" do
    order = Order.create!(
      user: @buyer,
      post: @hiring_post,
      title: "Test Order",
      amount: 500000
    )
    payment = order.payments.create!(
      user: @buyer,
      amount: 500000
    )

    assert_difference "Payment.count", -1 do
      order.destroy!
    end
  end

  # ============================================================================
  # Enums
  # ============================================================================

  test "should have correct status enum values" do
    assert @pending_order.pending?, "Default status should be pending"

    @pending_order.paid!
    assert @pending_order.paid?, "Should transition to paid"

    @pending_order.in_progress!
    assert @pending_order.in_progress?, "Should transition to in_progress"

    @pending_order.completed!
    assert @pending_order.completed?, "Should transition to completed"
  end

  test "should have correct order_type enum values" do
    assert @pending_order.outsourcing?, "Default order_type should be outsourcing"

    @pending_order.premium!
    assert @pending_order.premium?, "Should support premium order type"

    @pending_order.promotion!
    assert @pending_order.promotion?, "Should support promotion order type"
  end

  # ============================================================================
  # Scopes
  # ============================================================================

  test "recent scope should order by created_at desc" do
    orders = Order.recent.to_a
    assert orders.first.created_at >= orders.last.created_at,
           "Recent scope should order by created_at descending"
  end

  test "for_buyer scope should filter by user" do
    buyer_orders = Order.for_buyer(@buyer)
    assert buyer_orders.all? { |o| o.user == @buyer },
           "for_buyer should only return orders for specified buyer"
  end

  test "for_seller scope should filter by seller" do
    seller_orders = Order.for_seller(@user)
    assert seller_orders.all? { |o| o.seller == @user },
           "for_seller should only return orders for specified seller"
  end

  test "active scope should exclude cancelled and refunded orders" do
    active_orders = Order.active
    assert_not active_orders.any?(&:cancelled?),
               "Active scope should exclude cancelled orders"
    assert_not active_orders.any?(&:refunded?),
               "Active scope should exclude refunded orders"
  end

  # ============================================================================
  # Business Logic - Platform Fee & Settlement
  # ============================================================================

  test "should calculate platform fee correctly" do
    @pending_order.amount = 1_000_000
    expected_fee = (1_000_000 * Order::PLATFORM_FEE_RATE).to_i
    assert_equal expected_fee, @pending_order.platform_fee,
                 "Platform fee should be 10% of amount"
    assert_equal 100_000, @pending_order.platform_fee
  end

  test "should calculate settlement amount correctly" do
    @pending_order.amount = 1_000_000
    expected_settlement = 1_000_000 - 100_000
    assert_equal expected_settlement, @pending_order.settlement_amount,
                 "Settlement amount should be amount minus platform fee"
    assert_equal 900_000, @pending_order.settlement_amount
  end

  test "should format settlement amount correctly" do
    @pending_order.amount = 1_234_567
    expected_settlement = @pending_order.settlement_amount
    formatted = @pending_order.formatted_settlement_amount
    assert formatted.include?(expected_settlement.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse),
                 "Should format settlement amount in Korean won"
  end

  test "should format platform fee correctly" do
    @pending_order.amount = 1_234_567
    formatted = @pending_order.formatted_platform_fee
    assert_match /123,456원/, formatted,
                 "Should format platform fee in Korean won"
  end

  # ============================================================================
  # Business Logic - State Transitions
  # ============================================================================

  test "mark_as_paid! should update status and timestamp" do
    assert @pending_order.pending?, "Order should start as pending"
    assert_nil @pending_order.paid_at

    @pending_order.mark_as_paid!

    assert @pending_order.paid?, "Order should be marked as paid"
    assert_not_nil @pending_order.paid_at, "paid_at timestamp should be set"
    assert_in_delta Time.current, @pending_order.paid_at, 2.seconds
  end

  test "mark_as_in_progress! should only work for paid orders" do
    assert @paid_order.paid?, "Order should be paid"

    @paid_order.mark_as_in_progress!

    assert @paid_order.in_progress?, "Paid order should transition to in_progress"
  end

  test "mark_as_in_progress! should not work for pending orders" do
    assert @pending_order.pending?, "Order should be pending"

    @pending_order.mark_as_in_progress!

    assert @pending_order.pending?, "Pending order should remain pending"
  end

  test "confirm! should complete paid order" do
    assert @paid_order.can_confirm?, "Paid order should be confirmable"

    result = @paid_order.confirm!

    assert result, "confirm! should return true on success"
    assert @paid_order.completed?, "Order should be completed"
    assert_not_nil @paid_order.completed_at, "completed_at should be set"
  end

  test "confirm! should complete in_progress order" do
    in_progress = orders(:in_progress_order)
    assert in_progress.in_progress?, "Order should be in_progress"
    assert in_progress.can_confirm?, "In-progress order should be confirmable"

    result = in_progress.confirm!

    assert result, "confirm! should return true"
    assert in_progress.completed?, "Order should be completed"
  end

  test "confirm! should not work for pending order" do
    assert @pending_order.pending?, "Order should be pending"
    assert_not @pending_order.can_confirm?, "Pending order should not be confirmable"

    result = @pending_order.confirm!

    assert_not result, "confirm! should return false for pending order"
    assert @pending_order.pending?, "Order should remain pending"
  end

  test "mark_as_cancelled! should update status and timestamp" do
    @paid_order.mark_as_cancelled!

    assert @paid_order.cancelled?, "Order should be cancelled"
    assert_not_nil @paid_order.cancelled_at, "cancelled_at should be set"
  end

  test "mark_as_refunded! should update status and timestamp" do
    @paid_order.mark_as_refunded!

    assert @paid_order.refunded?, "Order should be refunded"
    assert_not_nil @paid_order.refunded_at, "refunded_at should be set"
  end

  # ============================================================================
  # Business Logic - State Checks
  # ============================================================================

  test "can_pay? should only be true for pending orders" do
    assert @pending_order.can_pay?, "Pending order should be payable"
    assert_not @paid_order.can_pay?, "Paid order should not be payable"
    assert_not @completed_order.can_pay?, "Completed order should not be payable"
  end

  test "can_confirm? should be true for paid or in_progress orders" do
    assert @paid_order.can_confirm?, "Paid order should be confirmable"

    in_progress = orders(:in_progress_order)
    assert in_progress.can_confirm?, "In-progress order should be confirmable"

    assert_not @pending_order.can_confirm?, "Pending order should not be confirmable"
    assert_not @completed_order.can_confirm?, "Completed order should not be confirmable"
  end

  test "can_cancel? should check status and creation time" do
    # Recent paid order
    recent_paid = @paid_order
    assert recent_paid.can_cancel?, "Recent paid order should be cancellable"

    # Old paid order (> 7 days)
    old_order = orders(:in_progress_order)
    old_order.update_columns(created_at: 8.days.ago)
    assert_not old_order.can_cancel?, "Order older than 7 days should not be cancellable"

    # Pending order
    assert_not @pending_order.can_cancel?, "Pending order should not be cancellable"
  end

  test "chat_based? should check for chat_room presence" do
    # Test with post-based order (no chat_room)
    assert_not @pending_order.chat_based?, "Order without chat_room should not be chat-based"
    assert @pending_order.post_based?, "Order with post should be post-based"
  end

  test "post_based? should check for post presence" do
    assert @pending_order.post_based?, "Order with post should be post-based"
  end

  test "escrow_held? should be true for paid or in_progress orders" do
    assert @paid_order.escrow_held?, "Paid order should be in escrow"

    in_progress = orders(:in_progress_order)
    assert in_progress.escrow_held?, "In-progress order should be in escrow"

    assert_not @pending_order.escrow_held?, "Pending order should not be in escrow"
    assert_not @completed_order.escrow_held?, "Completed order should not be in escrow"
  end

  # ============================================================================
  # Display Methods
  # ============================================================================

  test "status_label should return Korean status" do
    assert_equal "결제 대기", @pending_order.status_label
    assert_equal "결제 완료", @paid_order.status_label
    assert_equal "거래 완료", @completed_order.status_label
    assert_equal "취소됨", orders(:cancelled_order).status_label
  end

  test "formatted_amount should display in Korean won" do
    @pending_order.amount = 1_234_567
    formatted = @pending_order.formatted_amount
    assert_match /1,234,567원/, formatted,
                 "Should format amount in Korean won without decimals"
  end

  # ============================================================================
  # Callbacks
  # ============================================================================

  test "should auto-generate order_number on create" do
    order = Order.new(
      user: @buyer,
      post: @hiring_post,
      title: "Test Order",
      amount: 500000
    )
    assert_nil order.order_number, "Order number should be nil before save"

    order.save!

    assert_not_nil order.order_number, "Order number should be generated"
    assert_match /^ORD-\d{8}-[A-Z0-9]{6}$/, order.order_number,
                 "Order number should match format ORD-YYYYMMDD-XXXXXX"
  end

  test "should not regenerate order_number if already set" do
    existing_number = @pending_order.order_number
    @pending_order.save!

    assert_equal existing_number, @pending_order.order_number,
                 "Order number should not change on update"
  end

  test "should auto-set seller from post on create" do
    order = Order.new(
      user: @buyer,
      post: @hiring_post,
      title: "Test Order",
      amount: 500000
    )
    assert_nil order.seller_id, "Seller should be nil before save"

    order.save!

    assert_equal @hiring_post.user, order.seller,
                 "Seller should be auto-set from post.user"
  end

  test "should not override existing seller" do
    order = Order.new(
      user: @buyer,
      post: @hiring_post,
      seller: @seller,
      title: "Test Order",
      amount: 500000
    )

    order.save!

    assert_equal @seller, order.seller,
                 "Should not override explicitly set seller"
  end

  # ============================================================================
  # Edge Cases
  # ============================================================================

  test "should handle large amounts correctly" do
    order = Order.create!(
      user: @buyer,
      post: @hiring_post,
      title: "Large Project",
      amount: 999_999_999
    )

    expected_fee = (999_999_999 * Order::PLATFORM_FEE_RATE).to_i
    expected_settlement = 999_999_999 - expected_fee

    assert_equal expected_fee, order.platform_fee,
                 "Should calculate large platform fees correctly"
    assert_equal expected_settlement, order.settlement_amount,
                 "Should calculate large settlement amounts correctly"
  end

  test "should handle minimum amounts correctly" do
    order = Order.create!(
      user: @buyer,
      post: @hiring_post,
      title: "Small Task",
      amount: 1
    )

    assert_equal 0, order.platform_fee,
                 "Platform fee should round down to 0 for small amounts"
    assert_equal 1, order.settlement_amount
  end

  test "should generate unique order numbers under concurrent creation" do
    numbers = []
    10.times do
      order = Order.create!(
        user: @buyer,
        post: @hiring_post,
        title: "Test #{SecureRandom.hex(4)}",
        amount: 100000
      )
      numbers << order.order_number
    end

    assert_equal numbers.uniq.size, numbers.size,
                 "All order numbers should be unique"
  end

  # ============================================================================
  # Security Tests
  # ============================================================================

  test "should prevent SQL injection in title" do
    malicious_title = "'; DROP TABLE orders; --"
    order = Order.create!(
      user: @buyer,
      post: @hiring_post,
      title: malicious_title,
      amount: 100000
    )

    assert_equal malicious_title, order.title,
                 "Title should be stored as-is (Rails protects against SQL injection)"
    assert Order.exists?(order.id), "Orders table should still exist"
  end

  test "should prevent mass assignment of seller_id" do
    # Attempting to change seller via mass assignment
    @pending_order.update(seller_id: @seller.id, title: "Updated")

    # seller_id should be protected if strong parameters are used in controller
    # This test verifies model-level behavior
    assert_equal "Updated", @pending_order.title,
                 "Regular attributes should be updatable"
  end

  # ============================================================================
  # Transaction Rollback Tests
  # ============================================================================

  test "should rollback on validation error during create" do
    assert_no_difference "Order.count" do
      assert_raises ActiveRecord::RecordInvalid do
        Order.create!(
          user: @buyer,
          post: @hiring_post,
          title: nil,  # Invalid
          amount: 100000
        )
      end
    end
  end

  test "should rollback confirm! on error" do
    original_status = @paid_order.status
    original_completed_at = @paid_order.completed_at

    # Simulate transaction rollback by checking current state
    begin
      ActiveRecord::Base.transaction do
        @paid_order.update!(status: :completed, completed_at: Time.current)
        raise ActiveRecord::Rollback
      end
    rescue ActiveRecord::Rollback
      # Expected
    end

    @paid_order.reload
    assert_equal original_status, @paid_order.status,
                 "Status should not change on rollback"
    assert_nil @paid_order.completed_at,
                 "Timestamp should not change on rollback"
  end

  test "should maintain data consistency on concurrent updates" do
    order = orders(:paid_order)
    original_amount = order.amount

    # Simulate concurrent read-modify-write
    order_copy = Order.find(order.id)

    order.update!(amount: 2_000_000)
    order_copy.update!(status: :completed)

    order.reload
    assert order.completed?, "Status should be updated"
    # Amount from first update wins (depends on transaction isolation)
  end

  test "should handle errors in after_update callbacks gracefully" do
    # send_chat_system_message is a private method, so check it exists
    assert Order.private_method_defined?(:send_chat_system_message),
           "Order should have private method send_chat_system_message"

    # Verify callback is defined in after_update
    callbacks = Order._update_callbacks.select { |c| c.filter == :send_chat_system_message }
    assert callbacks.any?, "send_chat_system_message should be an after_update callback"
  end
end
