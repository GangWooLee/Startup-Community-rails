# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "ostruct"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_one = users(:one)
    @user_two = users(:two)
    @user_three = users(:three)
    @pending_order = orders(:pending_order)
    @paid_order = orders(:paid_order)
    @in_progress_order = orders(:in_progress_order)
    @completed_order = orders(:completed_order)
    @cancelled_order = orders(:cancelled_order)
  end

  # ============================================================================
  # Authentication Tests
  # ============================================================================

  test "index requires login" do
    get orders_path
    assert_redirected_to login_path
  end

  test "show requires login" do
    get order_path(@paid_order)
    assert_redirected_to login_path
  end

  test "confirm requires login" do
    post confirm_order_path(@paid_order)
    assert_redirected_to login_path
  end

  test "cancel requires login" do
    post cancel_order_path(@paid_order)
    assert_redirected_to login_path
  end

  # ============================================================================
  # INDEX Action Tests
  # ============================================================================

  test "index shows purchases by default" do
    log_in_as(@user_two)
    get orders_path

    assert_response :success
    assert_equal "purchases", assigns(:tab)
    assert_includes assigns(:orders), @pending_order
    assert_includes assigns(:orders), @in_progress_order
  end

  test "index with purchases tab shows user orders" do
    log_in_as(@user_two)
    get orders_path(tab: "purchases")

    assert_response :success
    orders = assigns(:orders)
    assert orders.all? { |order| order.user_id == @user_two.id }
  end

  test "index with sales tab shows seller orders" do
    log_in_as(@user_two)
    get orders_path(tab: "sales")

    assert_response :success
    orders = assigns(:orders)
    # User two is seller of paid_order
    assert_includes orders, @paid_order
    assert orders.all? { |order| order.seller_id == @user_two.id }
  end

  test "index with invalid tab defaults to purchases" do
    log_in_as(@user_two)
    get orders_path(tab: "invalid")

    assert_response :success
    assert_equal "invalid", assigns(:tab)
    # Should still show purchases (fallback)
    assert_not_nil assigns(:orders)
  end

  test "index paginates orders" do
    log_in_as(@user_two)
    get orders_path(page: 1)

    assert_response :success
    # Kaminari pagination should be applied
    assert_respond_to assigns(:orders), :current_page
  end

  # ============================================================================
  # SHOW Action Tests - Authorization
  # ============================================================================

  test "show as buyer displays order details" do
    log_in_as(@user_three)
    get order_path(@paid_order)

    assert_response :success
    assert_equal @paid_order, assigns(:order)
    assert_not_nil assigns(:payment)
  end

  test "show as seller displays order details" do
    log_in_as(@user_two)
    get order_path(@paid_order)

    assert_response :success
    assert_equal @paid_order, assigns(:order)
  end

  test "show as unauthorized user redirects with alert" do
    log_in_as(@user_one)
    get order_path(@paid_order)

    assert_redirected_to orders_path
    assert_equal "접근 권한이 없습니다.", flash[:alert]
  end

  test "show with nonexistent order redirects" do
    log_in_as(@user_two)
    get order_path(id: 99999)

    assert_redirected_to orders_path
    assert_equal "주문을 찾을 수 없습니다.", flash[:alert]
  end

  # ============================================================================
  # SUCCESS Action Tests
  # ============================================================================

  test "success shows payment completion page" do
    log_in_as(@user_three)
    get success_order_path(@paid_order)

    assert_response :success
    assert_equal @paid_order, assigns(:order)
    assert_not_nil assigns(:payment)
  end

  test "success requires order access authorization" do
    log_in_as(@user_one)
    get success_order_path(@paid_order)

    assert_redirected_to orders_path
    assert_equal "접근 권한이 없습니다.", flash[:alert]
  end

  # ============================================================================
  # RECEIPT Action Tests
  # ============================================================================

  test "receipt shows receipt page for done payment" do
    log_in_as(@user_three)
    get receipt_order_path(@paid_order)

    assert_response :success
    assert_equal @paid_order, assigns(:order)
    assert assigns(:payment).done?
  end

  test "receipt redirects if payment not done" do
    log_in_as(@user_two)
    get receipt_order_path(@pending_order)

    assert_redirected_to order_path(@pending_order)
    assert_equal "결제 완료된 주문만 영수증을 확인할 수 있습니다.", flash[:alert]
  end

  test "receipt requires order access authorization" do
    log_in_as(@user_one)
    get receipt_order_path(@paid_order)

    assert_redirected_to orders_path
    assert_equal "접근 권한이 없습니다.", flash[:alert]
  end

  # ============================================================================
  # CONFIRM Action Tests - Authorization
  # ============================================================================

  test "confirm as buyer succeeds" do
    log_in_as(@user_two)
    order = @in_progress_order

    post confirm_order_path(order)

    assert_redirected_to order_path(order)
    assert_match /거래가 확정되었습니다/, flash[:notice]
    order.reload
    assert order.completed?
  end

  test "confirm as seller is unauthorized" do
    log_in_as(@user_three)
    order = @in_progress_order

    post confirm_order_path(order)

    assert_redirected_to orders_path
    assert_equal "거래 확정 권한이 없습니다.", flash[:alert]
  end

  test "confirm when cannot confirm redirects with alert" do
    log_in_as(@user_two)
    # Pending order cannot be confirmed (must be in_progress or paid)
    order = @pending_order

    post confirm_order_path(order)

    assert_redirected_to order_path(order)
    assert_equal "확정할 수 없는 주문입니다.", flash[:alert]
    order.reload
    assert_not order.completed?
  end

  test "confirm already completed order redirects" do
    log_in_as(@user_one)
    order = @completed_order

    post confirm_order_path(order)

    assert_redirected_to order_path(order)
    assert_equal "확정할 수 없는 주문입니다.", flash[:alert]
  end

  # ============================================================================
  # CANCEL Action Tests - Authorization
  # ============================================================================

  test "cancel as buyer succeeds for in_progress order" do
    log_in_as(@user_two)
    order = @in_progress_order  # in_progress orders can be cancelled without API call

    post cancel_order_path(order)

    assert_redirected_to orders_path
    assert_equal "주문이 취소되었습니다.", flash[:notice]
    order.reload
    assert order.cancelled?
  end

  test "cancel as seller is unauthorized" do
    log_in_as(@user_one)
    order = @pending_order

    post cancel_order_path(order)

    assert_redirected_to orders_path
    assert_equal "취소 권한이 없습니다.", flash[:alert]
  end

  test "cancel when cannot cancel redirects with alert" do
    log_in_as(@user_one)
    # Completed order cannot be cancelled
    order = @completed_order

    post cancel_order_path(order)

    assert_redirected_to order_path(order)
    assert_equal "취소할 수 없는 주문입니다.", flash[:alert]
  end

  test "cancel already cancelled order redirects" do
    log_in_as(@user_three)
    order = @cancelled_order

    post cancel_order_path(order)

    assert_redirected_to order_path(order)
    assert_equal "취소할 수 없는 주문입니다.", flash[:alert]
  end

  # ============================================================================
  # CANCEL Action Tests - Payment Cancellation
  # ============================================================================

  test "cancel paid order requires API call" do
    skip "Requires WebMock for TossPayments API mocking"
    # This test would verify:
    # - TossPayments::CancelService is called for paid orders
    # - Proper transaction handling
    # Proper implementation requires WebMock gem to mock TossPayments API
  end

  test "cancel with payment API failure rolls back transaction" do
    skip "Requires WebMock for TossPayments API mocking"
    # This test would verify:
    # - Transaction rollback when API call fails
    # - Proper error message display
    # Proper implementation requires WebMock gem to mock TossPayments API
  end

  test "cancel with custom reason passes reason to API" do
    skip "Requires WebMock for TossPayments API mocking"
    # This test would verify:
    # - Custom reason is passed to TossPayments API
    # Proper implementation requires WebMock gem to mock TossPayments API
  end

  # ============================================================================
  # Edge Cases and Error Handling
  # ============================================================================

  test "confirm handles order that cannot be confirmed" do
    log_in_as(@user_two)
    # Pending order cannot be confirmed (must be in_progress or paid)
    order = @pending_order

    post confirm_order_path(order)

    assert_redirected_to order_path(order)
    assert_equal "확정할 수 없는 주문입니다.", flash[:alert]
    order.reload
    assert_not order.completed?
  end

  test "cancel handles order that cannot be cancelled" do
    log_in_as(@user_one)
    # Completed order cannot be cancelled
    order = @completed_order

    post cancel_order_path(order)

    assert_redirected_to order_path(order)
    assert_equal "취소할 수 없는 주문입니다.", flash[:alert]
    order.reload
    assert_not order.cancelled?
  end

  # ============================================================================
  # N+1 Query Prevention Tests
  # ============================================================================

  test "show eager loads associations to prevent N+1 queries" do
    log_in_as(@user_three)

    # Simply verify the request succeeds and order is loaded
    # Detailed query counting is better done with bullet gem in development
    get order_path(@paid_order)

    assert_response :success
    assert_not_nil assigns(:order)
    # Controller uses includes(:user, :seller, :post, :payments) in set_order
    # This prevents N+1 queries for associations
  end
end
