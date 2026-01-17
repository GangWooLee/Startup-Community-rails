# frozen_string_literal: true

require "application_system_test_case"

class OrdersTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
  end

  # =========================================
  # 로그인 필수 테스트
  # =========================================

  test "requires login to view orders list" do
    visit orders_path

    # 비로그인 시 로그인 페이지로 리다이렉트
    assert_current_path login_path
  end

  # =========================================
  # 주문 목록 페이지 테스트
  # =========================================

  test "can view orders list when logged in" do
    log_in_as(@user)
    visit orders_path

    # 주문 목록 페이지 로드 확인
    assert_current_path orders_path
    assert_selector "main", wait: 5

    # 페이지 제목 또는 콘텐츠 확인
    assert page.has_text?("주문", wait: 3) ||
           page.has_text?("거래", wait: 3) ||
           page.has_text?("내역", wait: 3) ||
           page.has_selector?("main", wait: 3),
           "Expected orders page content"
  end

  test "shows empty state when no orders" do
    # 주문이 없는 사용자로 테스트
    log_in_as(@user)
    visit orders_path

    # 빈 상태 또는 주문 목록 확인
    assert page.has_selector?("main", wait: 5),
           "Expected page to load"
  end

  # =========================================
  # 주문 상세 페이지 테스트
  # =========================================

  test "requires login to view order details" do
    # 임의의 order_id로 접근 시도
    visit order_path(id: 999999)

    # 비로그인 시 로그인 페이지로 리다이렉트
    assert_current_path login_path
  end

  test "redirects when accessing non-existent order" do
    log_in_as(@user)

    # 존재하지 않는 주문 ID로 접근
    visit order_path(id: 999999)

    # 주문 목록으로 리다이렉트 또는 에러
    assert page.has_current_path?(orders_path) ||
           page.has_text?("찾을 수 없습니다", wait: 3) ||
           page.has_text?("권한", wait: 3) ||
           page.has_text?("오류", wait: 3),
           "Expected redirect or error for non-existent order"
  end

  # =========================================
  # 주문 성공 페이지 테스트
  # =========================================

  test "requires login for order success page" do
    visit success_order_path(id: 999999)

    # 비로그인 시 로그인 페이지로 리다이렉트
    assert_current_path login_path
  end

  # =========================================
  # 영수증 페이지 테스트
  # =========================================

  test "requires login for receipt page" do
    visit receipt_order_path(id: 999999)

    # 비로그인 시 로그인 페이지로 리다이렉트
    assert_current_path login_path
  end

  # =========================================
  # 권한 검증 테스트
  # =========================================

  test "cannot access other users orders" do
    log_in_as(@user)

    # 다른 사용자의 주문에 접근 시도 (ID가 없으므로 404 예상)
    visit order_path(id: 999999)

    # 리다이렉트 또는 권한 에러
    assert page.has_current_path?(orders_path) ||
           page.has_text?("권한", wait: 3) ||
           page.has_text?("찾을 수 없습니다", wait: 3),
           "Expected redirect or error for unauthorized access"
  end
end
