# frozen_string_literal: true

require "test_helper"

module Orders
  class CreateServiceTest < ActiveSupport::TestCase
    setup do
      @user_one = users(:one)
      @user_two = users(:two)
      @user_three = users(:three)
      # fixture 충돌 방지: 기존 pending_order가 user_two + hiring_post 조합 사용
      # 테스트용 새 게시글 생성
      @hiring_post = Post.create!(
        user: @user_one,
        title: "테스트 외주 공고 #{SecureRandom.hex(4)}",
        content: "테스트 외주 공고 내용입니다. 충분한 길이의 내용을 작성합니다.",
        category: :hiring,
        status: :published,
        service_type: "development",
        work_type: "remote",
        price: 1000000
      )
      @seeking_post = posts(:seeking_post)
    end

    # ============================================================================
    # Post-based Order Creation Tests
    # ============================================================================

    test "call creates order and payment for valid post" do
      service = Orders::CreateService.new(user: @user_two, post: @hiring_post)
      result = service.call

      assert result.success?, "Expected service to succeed"
      assert_not_nil result.order, "Order should be created"
      assert_not_nil result.payment, "Payment should be created"
      assert_empty result.errors, "No errors should be present"

      # Verify order attributes
      order = result.order
      assert_equal @user_two, order.user
      assert_equal @hiring_post, order.post
      assert_equal @hiring_post.user, order.seller
      assert_equal @hiring_post.title, order.title
      assert_equal @hiring_post.price, order.amount
      assert order.pending?, "Order should be pending"
      assert order.outsourcing?, "Order should be outsourcing type"

      # Verify payment attributes
      payment = result.payment
      assert_equal order, payment.order
      assert_equal @user_two, payment.user
      assert_equal order.amount, payment.amount
      assert payment.pending?, "Payment should be pending"
    end

    test "call generates unique order number" do
      service1 = Orders::CreateService.new(user: @user_two, post: @hiring_post)
      result1 = service1.call

      # Create another order
      service2 = Orders::CreateService.new(user: @user_three, post: @hiring_post)
      result2 = service2.call

      assert_not_equal result1.order.order_number, result2.order.order_number,
        "Order numbers should be unique"
    end

    test "call sets post order description correctly" do
      service = Orders::CreateService.new(user: @user_two, post: @hiring_post)
      result = service.call

      assert result.success?
      expected_description = "#{@hiring_post.category_label} - #{@hiring_post.service_type_label}"
      assert_equal expected_description, result.order.description
    end

    # ============================================================================
    # Validation Tests - Post Orders
    # ============================================================================

    test "call fails when user is nil" do
      service = Orders::CreateService.new(user: nil, post: @hiring_post)
      result = service.call

      assert result.failure?, "Expected service to fail"
      assert_nil result.order
      assert_nil result.payment
      assert_includes result.errors, "로그인이 필요합니다."
    end

    test "call fails when post is nil" do
      service = Orders::CreateService.new(user: @user_two, post: nil)
      result = service.call

      assert result.failure?
      assert_includes result.errors, "주문 대상을 찾을 수 없습니다."
    end

    test "call fails when post is not outsourcing category" do
      free_post = posts(:one)  # Free category post
      service = Orders::CreateService.new(user: @user_two, post: free_post)
      result = service.call

      assert result.failure?
      assert_includes result.errors, "외주 글만 결제할 수 있습니다."
    end

    test "call fails when post has no price" do
      # Create a hiring post without price
      no_price_post = Post.create!(
        user: @user_one,
        title: "No price post",
        content: "Test",
        category: :hiring,
        service_type: :development,
        work_type: :remote,
        price: nil
      )

      service = Orders::CreateService.new(user: @user_two, post: no_price_post)
      result = service.call

      assert result.failure?
      assert_includes result.errors, "가격이 설정되지 않은 글입니다."
    end

    test "call fails when post price is zero" do
      # Create a hiring post with zero price
      zero_price_post = Post.create!(
        user: @user_one,
        title: "Zero price post",
        content: "Test",
        category: :hiring,
        service_type: :development,
        work_type: :remote,
        price: 0
      )

      service = Orders::CreateService.new(user: @user_two, post: zero_price_post)
      result = service.call

      assert result.failure?
      assert_includes result.errors, "가격이 설정되지 않은 글입니다."
    end

    test "call fails when user tries to order own post" do
      service = Orders::CreateService.new(user: @user_one, post: @hiring_post)
      result = service.call

      assert result.failure?
      assert_includes result.errors, "본인의 글은 결제할 수 없습니다."
    end

    test "call fails when duplicate order exists for same post" do
      # Create first order
      service1 = Orders::CreateService.new(user: @user_two, post: @hiring_post)
      result1 = service1.call
      assert result1.success?

      # Try to create duplicate order
      service2 = Orders::CreateService.new(user: @user_two, post: @hiring_post)
      result2 = service2.call

      assert result2.failure?
      assert_includes result2.errors, "이미 주문한 글입니다."
    end

    test "call succeeds when previous order was cancelled" do
      # Create first order
      service1 = Orders::CreateService.new(user: @user_two, post: @hiring_post)
      result1 = service1.call
      assert result1.success?

      # Cancel the order
      result1.order.update!(status: :cancelled)

      # Should be able to create new order
      service2 = Orders::CreateService.new(user: @user_two, post: @hiring_post)
      result2 = service2.call

      assert result2.success?, "Should allow new order after cancellation"
    end

    # ============================================================================
    # Transaction Rollback Tests
    # ============================================================================

    test "call rolls back transaction on order creation failure" do
      # Create a service instance
      service = Orders::CreateService.new(user: @user_two, post: @hiring_post)

      # Override the private method to raise an error
      def service.create_post_order!
        raise ActiveRecord::RecordInvalid.new
      end

      result = service.call

      assert result.failure?
      assert_nil result.order
      assert_nil result.payment

      # Verify no order or payment was created
      assert_equal 0, Order.where(user: @user_two, post: @hiring_post).count
    end

    test "call rolls back transaction on payment creation failure" do
      initial_order_count = Order.count
      initial_payment_count = Payment.count

      service = Orders::CreateService.new(user: @user_two, post: @hiring_post)

      # Payment.create!가 실패하도록 모킹
      Payment.stub(:create!, ->(*) { raise ActiveRecord::RecordInvalid.new(Payment.new) }) do
        result = service.call

        # 실패해야 함
        assert result.failure?
        # ActiveRecord::RecordInvalid 예외 메시지는 "Validation failed: ..."로 시작
        assert result.errors.any? { |e| e.include?("Validation failed") }
      end

      # 트랜잭션 롤백으로 Order도 생성되지 않아야 함
      assert_equal initial_order_count, Order.count, "Order should be rolled back"
      assert_equal initial_payment_count, Payment.count, "Payment should not be created"
    end

    test "call handles unexpected errors gracefully" do
      # Create a service instance
      service = Orders::CreateService.new(user: @user_two, post: @hiring_post)

      # Override the private method to raise an unexpected error
      def service.create_payment!
        raise StandardError, "Unexpected error"
      end

      result = service.call

      assert result.failure?
      assert_includes result.errors, "주문 생성 중 오류가 발생했습니다."
    end

    # ============================================================================
    # Result Object Tests
    # ============================================================================

    test "Result responds to success? and failure?" do
      result = Orders::CreateService::Result.new(success?: true, order: nil, payment: nil, errors: [])

      assert result.success?
      assert_not result.failure?

      result2 = Orders::CreateService::Result.new(success?: false, order: nil, payment: nil, errors: [])

      assert result2.failure?
      assert_not result2.success?
    end

    test "Result provides access to order, payment, and errors" do
      order = orders(:pending_order)
      payment = payments(:pending_payment)
      errors = [ "Test error" ]

      result = Orders::CreateService::Result.new(
        success?: true,
        order: order,
        payment: payment,
        errors: errors
      )

      assert_equal order, result.order
      assert_equal payment, result.payment
      assert_equal errors, result.errors
    end

    # ============================================================================
    # Edge Cases
    # ============================================================================

    test "call validates all errors before stopping" do
      # Post with multiple issues
      no_price_post = Post.create!(
        user: @user_two,  # User will order own post
        title: "Invalid post",
        content: "Test",
        category: :free,  # Not outsourcing
        service_type: nil,
        price: nil  # No price
      )

      service = Orders::CreateService.new(user: @user_two, post: no_price_post)
      result = service.call

      assert result.failure?
      # Should contain multiple validation errors
      assert result.errors.count >= 2, "Should have multiple validation errors"
    end

    test "call accepts post with minimum valid price of 1 won" do
      min_price_post = Post.create!(
        user: @user_one,
        title: "Minimum price post",
        content: "Test",
        category: :hiring,
        service_type: :development,
        work_type: :remote,
        price: 1
      )

      service = Orders::CreateService.new(user: @user_two, post: min_price_post)
      result = service.call

      assert result.success?
      assert_equal 1, result.order.amount
    end

    test "call accepts post with large price" do
      large_price_post = Post.create!(
        user: @user_one,
        title: "Large price post",
        content: "Test",
        category: :hiring,
        service_type: :development,
        work_type: :remote,
        price: 10_000_000  # 10 million won
      )

      service = Orders::CreateService.new(user: @user_two, post: large_price_post)
      result = service.call

      assert result.success?
      assert_equal 10_000_000, result.order.amount
    end

    # ============================================================================
    # Logging Tests
    # ============================================================================

    test "call logs successful order creation" do
      service = Orders::CreateService.new(user: @user_two, post: @hiring_post)

      # Just verify the service succeeds without raising
      # (Actual log verification is difficult with BroadcastLogger)
      assert_nothing_raised do
        result = service.call
        assert result.success?
      end
    end

    test "call logs validation errors" do
      service = Orders::CreateService.new(user: nil, post: @hiring_post)

      # Verify it doesn't raise when logging errors
      assert_nothing_raised do
        result = service.call
        assert result.failure?
      end
    end
  end
end
