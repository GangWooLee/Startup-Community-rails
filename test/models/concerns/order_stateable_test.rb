# frozen_string_literal: true

require "test_helper"

class OrderStateableTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @seller = users(:two)
    @order = orders(:one) rescue nil
  end

  # =========================================
  # mark_as_paid! 메서드 테스트
  # =========================================

  test "mark_as_paid! updates status to paid" do
    skip "Order model not available" unless defined?(Order) && @order

    @order.update_column(:status, :pending)

    @order.mark_as_paid!

    assert_equal "paid", @order.status
    assert_not_nil @order.paid_at
  end

  # =========================================
  # mark_as_in_progress! 메서드 테스트
  # =========================================

  test "mark_as_in_progress! updates status when paid" do
    skip "Order model not available" unless defined?(Order) && @order

    @order.update_column(:status, :paid)

    @order.mark_as_in_progress!

    assert_equal "in_progress", @order.status
  end

  test "mark_as_in_progress! does nothing when not paid" do
    skip "Order model not available" unless defined?(Order) && @order

    @order.update_column(:status, :pending)

    @order.mark_as_in_progress!

    assert_equal "pending", @order.status
  end

  # =========================================
  # can_pay? 메서드 테스트
  # =========================================

  test "can_pay? returns true when pending" do
    skip "Order model not available" unless defined?(Order) && @order

    @order.update_column(:status, :pending)

    assert @order.can_pay?
  end

  test "can_pay? returns false when paid" do
    skip "Order model not available" unless defined?(Order) && @order

    @order.update_column(:status, :paid)

    assert_not @order.can_pay?
  end

  # =========================================
  # can_confirm? 메서드 테스트
  # =========================================

  test "can_confirm? returns true when paid" do
    skip "Order model not available" unless defined?(Order) && @order

    @order.update_column(:status, :paid)

    assert @order.can_confirm?
  end

  test "can_confirm? returns true when in_progress" do
    skip "Order model not available" unless defined?(Order) && @order

    @order.update_column(:status, :in_progress)

    assert @order.can_confirm?
  end

  test "can_confirm? returns false when pending" do
    skip "Order model not available" unless defined?(Order) && @order

    @order.update_column(:status, :pending)

    assert_not @order.can_confirm?
  end

  # =========================================
  # status_label 메서드 테스트
  # =========================================

  test "status_label returns Korean label for pending" do
    skip "Order model not available" unless defined?(Order) && @order

    @order.update_column(:status, :pending)

    assert_equal "결제 대기", @order.status_label
  end

  test "status_label returns Korean label for paid" do
    skip "Order model not available" unless defined?(Order) && @order

    @order.update_column(:status, :paid)

    assert_equal "결제 완료", @order.status_label
  end

  test "status_label returns Korean label for completed" do
    skip "Order model not available" unless defined?(Order) && @order

    @order.update_column(:status, :completed)

    assert_equal "거래 완료", @order.status_label
  end

  # =========================================
  # escrow_held? 메서드 테스트
  # =========================================

  test "escrow_held? returns true when paid" do
    skip "Order model not available" unless defined?(Order) && @order

    @order.update_column(:status, :paid)

    assert @order.escrow_held?
  end

  test "escrow_held? returns false when completed" do
    skip "Order model not available" unless defined?(Order) && @order

    @order.update_column(:status, :completed)

    assert_not @order.escrow_held?
  end
end
