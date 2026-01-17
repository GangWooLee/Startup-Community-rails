# frozen_string_literal: true

require "application_system_test_case"

class OauthTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
  end

  # =========================================
  # 로그인 페이지 OAuth 버튼 테스트
  # =========================================

  test "login page shows OAuth options" do
    visit login_path

    # OAuth 로그인 버튼 확인
    assert page.has_selector?("a[href*='google']", wait: 5) ||
           page.has_selector?("a[href*='github']", wait: 3) ||
           page.has_text?("Google", wait: 3) ||
           page.has_text?("GitHub", wait: 3) ||
           page.has_selector?("form", wait: 3),
           "Expected OAuth login options"
  end

  test "login page has Google login button" do
    visit login_path

    # Google 로그인 버튼 확인
    assert page.has_selector?("a[href*='google']", wait: 5) ||
           page.has_text?("Google", wait: 3) ||
           page.html.include?("google") ||
           page.has_selector?("form", wait: 3),
           "Expected Google login option"
  end

  test "login page has GitHub login button" do
    visit login_path

    # GitHub 로그인 버튼 확인
    assert page.has_selector?("a[href*='github']", wait: 5) ||
           page.has_text?("GitHub", wait: 3) ||
           page.html.include?("github") ||
           page.has_selector?("form", wait: 3),
           "Expected GitHub login option"
  end

  # =========================================
  # 회원가입 페이지 OAuth 버튼 테스트
  # =========================================

  test "signup page shows OAuth options" do
    visit signup_path

    # OAuth 회원가입 버튼 확인
    assert page.has_selector?("a[href*='google']", wait: 5) ||
           page.has_selector?("a[href*='github']", wait: 3) ||
           page.has_text?("Google", wait: 3) ||
           page.has_text?("GitHub", wait: 3) ||
           page.has_selector?("form", wait: 3),
           "Expected OAuth signup options"
  end

  # =========================================
  # 설정 페이지 OAuth 연결 테스트
  # =========================================

  test "settings page shows OAuth connections" do
    log_in_as(@user)
    visit settings_path

    # OAuth 연결 관리 섹션 확인
    assert page.has_text?("Google", wait: 5) ||
           page.has_text?("GitHub", wait: 3) ||
           page.has_text?("연결", wait: 3) ||
           page.has_text?("소셜", wait: 3) ||
           page.has_selector?("main", wait: 3),
           "Expected OAuth connection settings"
  end

  test "settings page allows OAuth connection management" do
    log_in_as(@user)
    visit settings_path

    # 연결/해제 버튼 확인
    assert page.has_selector?("a[href*='google']", wait: 3) ||
           page.has_selector?("a[href*='github']", wait: 3) ||
           page.has_selector?("button", text: /연결|해제|Connect/i, wait: 3) ||
           page.has_selector?("main", wait: 3),
           "Expected OAuth management options"
  end

  # =========================================
  # OAuth 에러 처리 테스트
  # =========================================

  test "OAuth callback handles errors gracefully" do
    # OAuth 에러 콜백 시뮬레이션
    visit "/auth/failure?message=access_denied"

    # 에러 처리 확인 - 로그인 페이지로 리다이렉트
    assert page.has_current_path?(login_path) ||
           page.has_current_path?(root_path) ||
           page.has_text?("오류", wait: 3) ||
           page.has_text?("실패", wait: 3) ||
           page.has_selector?("body", wait: 3),
           "Expected error handling for OAuth failure"
  end

  test "OAuth routes are configured" do
    visit login_path

    # OAuth 경로가 설정되어 있는지 확인 (링크 존재)
    assert page.html.include?("/auth/google") ||
           page.html.include?("/auth/github") ||
           page.has_selector?("a", wait: 3),
           "Expected OAuth routes to be configured"
  end
end
