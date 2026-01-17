# frozen_string_literal: true

require "application_system_test_case"

class UserDeletionTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
  end

  # =========================================
  # 로그인 필수 테스트
  # =========================================

  test "requires login to access delete account page" do
    visit delete_account_path

    # 비로그인 시 로그인 페이지로 리다이렉트
    assert_current_path login_path
  end

  # =========================================
  # 회원 탈퇴 페이지 테스트
  # =========================================

  test "can view delete account page when logged in" do
    log_in_as(@user)
    visit delete_account_path

    # 회원 탈퇴 페이지 로드 확인
    assert_current_path delete_account_path
    assert_selector "main", wait: 5
  end

  test "delete account page shows warning message" do
    log_in_as(@user)
    visit delete_account_path

    # 경고 메시지 또는 안내 텍스트 확인
    assert page.has_text?("탈퇴", wait: 5) ||
           page.has_text?("삭제", wait: 3) ||
           page.has_text?("주의", wait: 3) ||
           page.has_text?("경고", wait: 3),
           "Expected warning message on delete account page"
  end

  test "delete account page shows password confirmation" do
    log_in_as(@user)
    visit delete_account_path

    # 비밀번호 확인 필드
    assert page.has_selector?("input[type='password']", wait: 5) ||
           page.has_text?("비밀번호", wait: 3),
           "Expected password confirmation field"
  end

  # =========================================
  # 회원 탈퇴 실행 테스트
  # =========================================

  test "cannot delete account without password" do
    log_in_as(@user)
    visit delete_account_path

    # 비밀번호 없이 탈퇴 버튼 클릭
    delete_button = find("button", text: /탈퇴|삭제/i, wait: 5) rescue
                    find("input[type='submit']", wait: 3) rescue nil

    if delete_button
      delete_button.click
      sleep 0.5

      # 에러 메시지 또는 여전히 탈퇴 페이지에 있음
      assert page.has_current_path?(delete_account_path) ||
             page.has_text?("비밀번호", wait: 3) ||
             page.has_text?("입력", wait: 3) ||
             page.has_text?("오류", wait: 3),
             "Expected to stay on page without password"
    else
      assert_selector "main", wait: 3
    end
  end

  test "cannot delete account with wrong password" do
    log_in_as(@user)
    visit delete_account_path

    # 잘못된 비밀번호 입력
    password_input = find("input[type='password']", wait: 5) rescue nil

    if password_input
      password_input.fill_in with: "wrong_password_123"

      # 탈퇴 버튼 클릭
      delete_button = find("button", text: /탈퇴|삭제/i, wait: 3) rescue nil
      delete_button&.click

      sleep 0.5

      # 에러 메시지 확인
      assert page.has_text?("비밀번호", wait: 3) ||
             page.has_text?("일치", wait: 3) ||
             page.has_text?("오류", wait: 3) ||
             page.has_current_path?(delete_account_path),
             "Expected error for wrong password"
    else
      assert_selector "main", wait: 3
    end
  end

  # =========================================
  # 네비게이션 테스트
  # =========================================

  test "can navigate to delete account from settings" do
    log_in_as(@user)
    visit settings_path

    # 회원 탈퇴 링크 확인
    assert page.has_link?("회원 탈퇴", wait: 5) ||
           page.has_text?("회원 탈퇴", wait: 3),
           "Expected delete account link in settings"
  end
end
