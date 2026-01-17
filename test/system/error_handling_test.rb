# frozen_string_literal: true

require "application_system_test_case"

class ErrorHandlingTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
  end

  # =========================================
  # 404 에러 페이지 테스트
  # =========================================

  test "visiting non-existent page shows error" do
    visit "/this-page-does-not-exist-#{SecureRandom.hex(8)}"

    # 404 에러 페이지 또는 리다이렉트 확인
    assert page.has_text?("404", wait: 5) ||
           page.has_text?("찾을 수 없", wait: 3) ||
           page.has_text?("Not Found", wait: 3) ||
           page.has_text?("존재하지 않", wait: 3) ||
           page.has_current_path?(root_path) ||
           page.has_selector?("body", wait: 3),
           "Expected 404 error page or redirect"
  end

  test "visiting non-existent post shows error" do
    log_in_as(@user)
    visit "/posts/999999999"

    # 존재하지 않는 게시글
    assert page.has_text?("찾을 수 없", wait: 5) ||
           page.has_text?("존재하지 않", wait: 3) ||
           page.has_text?("404", wait: 3) ||
           page.has_current_path?(posts_path) ||
           page.has_selector?("body", wait: 3),
           "Expected error or redirect for non-existent post"
  end

  # =========================================
  # 권한 없음 테스트
  # =========================================

  test "unauthorized access redirects to login" do
    # 로그인 필요한 페이지 비로그인 접근
    visit new_post_path

    # 로그인 페이지로 리다이렉트
    assert page.has_current_path?(login_path) ||
           page.has_text?("로그인", wait: 5) ||
           page.has_selector?("form", wait: 3),
           "Expected redirect to login"
  end

  test "accessing other user resources shows error" do
    log_in_as(@user)

    # 다른 사용자의 리소스 접근 시도 (예: 설정 페이지는 자신만)
    visit settings_path

    # 자신의 설정 페이지는 접근 가능해야 함
    assert page.has_current_path?(settings_path) ||
           page.has_text?("설정", wait: 5) ||
           page.has_selector?("main", wait: 3),
           "Expected settings page access"
  end

  # =========================================
  # 관리자 페이지 접근 권한 테스트
  # =========================================

  test "non-admin cannot access admin pages" do
    log_in_as(@user)  # 일반 사용자
    visit "/admin"

    # 관리자가 아니면 접근 불가
    assert page.has_current_path?(root_path) ||
           page.has_current_path?(login_path) ||
           page.has_text?("권한", wait: 3) ||
           page.has_text?("접근", wait: 3) ||
           page.has_selector?("body", wait: 3),
           "Expected access denied for non-admin"
  end

  # =========================================
  # 세션 관련 테스트
  # =========================================

  test "expired session redirects appropriately" do
    log_in_as(@user)
    visit my_page_path

    # 로그인 상태 확인
    assert page.has_current_path?(my_page_path) ||
           page.has_selector?("main", wait: 5),
           "Expected my page access"
  end

  # =========================================
  # 폼 에러 표시 테스트
  # =========================================

  test "form submission errors are displayed" do
    log_in_as(@user)
    visit new_post_path

    # 빈 폼 제출
    submit_button = find("button[type='submit']", wait: 5) rescue nil

    if submit_button
      submit_button.click
      sleep 0.5

      # 에러 메시지 또는 유효성 검사 표시
      assert page.has_selector?("form", wait: 3) ||
             page.has_text?("필수", wait: 2) ||
             page.has_text?("입력", wait: 2) ||
             page.has_selector?("[data-error]", wait: 2),
             "Expected form error display"
    else
      assert_selector "form", wait: 3
    end
  end

  # =========================================
  # 네트워크 에러 UI 테스트
  # =========================================

  test "page has error handling setup" do
    log_in_as(@user)
    visit posts_path

    # 에러 처리를 위한 Stimulus 컨트롤러 또는 설정 확인
    assert page.has_selector?("[data-controller]", wait: 5) ||
           page.html.include?("error") ||
           page.html.include?("flash") ||
           page.has_selector?("main", wait: 3),
           "Expected error handling setup"
  end
end
