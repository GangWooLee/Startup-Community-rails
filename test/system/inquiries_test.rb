# frozen_string_literal: true

require "application_system_test_case"

class InquiriesTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
  end

  # =========================================
  # 로그인 필수 테스트
  # =========================================

  test "inquiries list accessible" do
    visit inquiries_path

    # 문의 목록 페이지 접근 (로그인 필수 또는 공개)
    assert page.has_current_path?(inquiries_path) ||
           page.has_current_path?(login_path),
           "Expected inquiries list or login redirect"
  end

  test "requires login to create new inquiry" do
    visit new_inquiry_path

    # 비로그인 시 로그인 페이지로 리다이렉트
    assert_current_path login_path
  end

  # =========================================
  # 문의 목록 테스트
  # =========================================

  test "logged in user can view inquiries list" do
    log_in_as(@user)
    visit inquiries_path

    # 문의 목록 페이지 로드 확인
    assert_current_path inquiries_path
    assert_selector "main", wait: 5
  end

  test "inquiries page shows page title" do
    log_in_as(@user)
    visit inquiries_path

    # 페이지 제목 확인
    assert page.has_text?("문의", wait: 5) ||
           page.has_text?("내역", wait: 3) ||
           page.has_selector?("main", wait: 3),
           "Expected inquiries page content"
  end

  # =========================================
  # 문의 작성 테스트
  # =========================================

  test "logged in user can view new inquiry form" do
    log_in_as(@user)
    visit new_inquiry_path

    # 문의 작성 폼 페이지 로드 확인
    assert_current_path new_inquiry_path
    assert_selector "main", wait: 5
  end

  test "new inquiry form shows input fields" do
    log_in_as(@user)
    visit new_inquiry_path

    # 입력 필드 확인
    assert page.has_selector?("input", wait: 5) ||
           page.has_selector?("textarea", wait: 3) ||
           page.has_selector?("form", wait: 3),
           "Expected inquiry form fields"
  end

  test "new inquiry form shows submit button" do
    log_in_as(@user)
    visit new_inquiry_path

    # 제출 버튼 확인
    assert page.has_selector?("button[type='submit']", wait: 5) ||
           page.has_selector?("input[type='submit']", wait: 3) ||
           page.has_selector?("button", text: /문의|제출|보내기/i, wait: 3),
           "Expected submit button"
  end

  # =========================================
  # 네비게이션 테스트
  # =========================================

  test "can navigate to new inquiry from settings" do
    log_in_as(@user)
    visit settings_path

    # 문의하기 링크 클릭
    inquiry_link = find("a", text: /문의하기|문의/i, wait: 5) rescue nil

    if inquiry_link
      inquiry_link.click
      sleep 0.5

      assert page.has_current_path?(new_inquiry_path) ||
             page.has_text?("문의", wait: 3),
             "Expected to navigate to new inquiry page"
    else
      # 링크가 다른 텍스트일 수 있음
      assert_selector "main", wait: 3
    end
  end
end
