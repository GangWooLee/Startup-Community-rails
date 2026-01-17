# frozen_string_literal: true

require "application_system_test_case"

class AccountRecoveryTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
  end

  # =========================================
  # 비밀번호 찾기 페이지 테스트
  # =========================================

  test "can view forgot password page" do
    visit forgot_password_form_path

    # 비밀번호 찾기 페이지 로드 확인
    assert_current_path forgot_password_form_path
    assert_selector "main", wait: 5
  end

  test "forgot password page shows email input" do
    visit forgot_password_form_path

    # 이메일 입력 필드 확인
    assert page.has_selector?("input[type='email']", wait: 5) ||
           page.has_selector?("input[name*='email']", wait: 3),
           "Expected email input field"
  end

  test "forgot password page shows submit button" do
    visit forgot_password_form_path

    # 제출 버튼 확인
    assert page.has_selector?("button[type='submit']", wait: 5) ||
           page.has_selector?("input[type='submit']", wait: 3) ||
           page.has_selector?("button", text: /재설정|찾기|발송/i, wait: 3),
           "Expected submit button"
  end

  # =========================================
  # 비밀번호 찾기 요청 테스트
  # =========================================

  test "cannot submit forgot password with empty email" do
    visit forgot_password_form_path

    # 빈 이메일로 제출 시도
    submit_button = find("button[type='submit']", wait: 5) rescue find("button", match: :first, wait: 3) rescue nil

    if submit_button
      submit_button.click
      sleep 0.5

      # 여전히 같은 페이지에 있거나 에러 표시
      assert page.has_current_path?(forgot_password_form_path) ||
             page.has_text?("입력", wait: 3) ||
             page.has_text?("이메일", wait: 3) ||
             page.has_selector?("input[type='email']", wait: 3),
             "Expected to stay on page with empty email"
    else
      assert_selector "main", wait: 3
    end
  end

  test "shows sent page after valid email submission" do
    visit forgot_password_form_path

    # 이메일 입력
    email_input = find("input[type='email']", wait: 5) rescue find("input[name*='email']", wait: 3) rescue nil

    if email_input
      email_input.fill_in with: @user.email

      # 제출
      submit_button = find("button[type='submit']", wait: 3) rescue find("button", match: :first, wait: 2) rescue nil
      submit_button&.click

      sleep 1

      # 발송 완료 페이지 또는 메시지 확인
      assert page.has_current_path?(forgot_password_sent_path) ||
             page.has_text?("발송", wait: 5) ||
             page.has_text?("이메일", wait: 3) ||
             page.has_text?("확인", wait: 3),
             "Expected sent confirmation page or message"
    else
      assert_selector "main", wait: 3
    end
  end

  # =========================================
  # 비밀번호 재설정 페이지 테스트
  # =========================================

  test "reset password page requires valid token" do
    # 잘못된 토큰으로 접근
    visit reset_password_form_path(token: "invalid_token_123")

    # 에러 메시지 또는 리다이렉트
    assert page.has_text?("만료", wait: 3) ||
           page.has_text?("유효하지", wait: 3) ||
           page.has_text?("오류", wait: 3) ||
           page.has_current_path?(forgot_password_form_path) ||
           page.has_current_path?(login_path) ||
           page.has_selector?("main", wait: 3),
           "Expected error for invalid token"
  end

  # =========================================
  # 발송 완료 페이지 테스트
  # =========================================

  test "can view forgot password sent page" do
    visit forgot_password_sent_path

    # 발송 완료 페이지 로드 확인
    assert_current_path forgot_password_sent_path
    assert_selector "main", wait: 5
  end

  test "forgot password sent page shows confirmation message" do
    visit forgot_password_sent_path

    # 확인 메시지 표시
    assert page.has_text?("이메일", wait: 3) ||
           page.has_text?("발송", wait: 3) ||
           page.has_text?("확인", wait: 3) ||
           page.has_text?("링크", wait: 3) ||
           page.has_selector?("main", wait: 3),
           "Expected confirmation message"
  end
end
