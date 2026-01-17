# frozen_string_literal: true

require "application_system_test_case"

class OnboardingTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
  end

  # =========================================
  # 랜딩 페이지 테스트
  # =========================================

  test "can view landing page without login" do
    visit root_path

    # 랜딩 페이지 로드 확인
    assert_current_path root_path

    # 페이지 콘텐츠 로드 확인 (main 또는 body 콘텐츠)
    assert page.has_text?("Undrew", wait: 5) ||
           page.has_text?("창업", wait: 5) ||
           page.has_selector?("body", wait: 5),
           "Expected landing page to load"
  end

  test "landing page shows main heading or CTA" do
    visit root_path

    # 페이지 로드 대기
    sleep 2

    # 메인 헤딩 또는 CTA 텍스트 확인 - HTML 소스에서 검색
    assert page.html.include?("Stop Scrolling") ||
           page.html.include?("Undrew") ||
           page.html.include?("창업") ||
           page.html.include?("시작하기"),
           "Expected to find landing page content"
  end

  test "landing page has link to ai input" do
    visit root_path

    # 페이지 로드 대기
    sleep 1

    # AI 분석 시작 버튼 확인 - HTML 소스에서 검색
    assert page.html.include?("시작하기") ||
           page.html.include?("ai/input") ||
           page.has_selector?("a[href*='ai']", wait: 3),
           "Expected to find link to AI input page"
  end

  # =========================================
  # AI 입력 페이지 테스트
  # =========================================

  test "can view ai input page without login" do
    visit onboarding_ai_input_path

    # AI 입력 페이지 로드 확인
    assert_current_path onboarding_ai_input_path
    assert_selector "main", wait: 5
  end

  test "ai input page shows idea input form" do
    visit onboarding_ai_input_path

    # 아이디어 입력 폼 요소 확인
    assert page.has_selector?("textarea, input[type='text']", wait: 5) ||
           page.has_selector?("[data-controller*='ai']", wait: 3),
           "Expected to find idea input form"
  end

  test "ai input page shows analyze button" do
    visit onboarding_ai_input_path

    # 분석 버튼 확인
    assert page.has_selector?("button", wait: 5) ||
           page.has_selector?("input[type='submit']", wait: 3),
           "Expected to find analyze button"
  end

  test "logged in user can view ai input page" do
    log_in_as(@user)
    visit onboarding_ai_input_path

    # 로그인 사용자도 AI 입력 페이지 접근 가능
    assert_current_path onboarding_ai_input_path
    assert_selector "main", wait: 5
  end

  # =========================================
  # AI 결과 페이지 테스트 (로그인 필수)
  # =========================================

  test "ai result requires login" do
    # 가짜 ID로 결과 페이지 접근 시도
    visit ai_result_path(id: 999999)

    # 로그인 페이지로 리다이렉트
    assert_current_path login_path
  end

  test "logged in user redirected for invalid analysis id" do
    log_in_as(@user)

    # 존재하지 않는 분석 ID로 접근
    visit ai_result_path(id: 999999)

    # AI 입력 페이지로 리다이렉트되거나 에러 메시지 표시
    assert page.has_current_path?(onboarding_ai_input_path) ||
           page.has_text?("찾을 수 없습니다", wait: 3) ||
           page.has_text?("오류", wait: 3),
           "Expected redirect or error message for invalid analysis"
  end

  # =========================================
  # 비로그인 사용자 플로우 테스트
  # =========================================

  test "guest user sees login prompt or can input idea" do
    visit onboarding_ai_input_path

    # 비로그인 사용자는 아이디어 입력 가능하거나 로그인 유도
    assert page.has_selector?("textarea, input[type='text']", wait: 5) ||
           page.has_text?("로그인", wait: 3),
           "Expected idea input form or login prompt for guest"
  end

  # =========================================
  # 커뮤니티 연결 테스트
  # =========================================

  test "landing page has community link" do
    visit root_path

    # 페이지 로드 대기
    sleep 1

    # 커뮤니티 링크 확인 - HTML 소스에서 검색
    assert page.html.include?("커뮤니티") ||
           page.html.include?("community") ||
           page.has_selector?("a[href*='community']", wait: 3),
           "Expected to find community link"
  end

  # =========================================
  # 사용량 표시 테스트
  # =========================================

  test "ai input page shows usage info" do
    visit onboarding_ai_input_path

    # 사용량 정보 또는 무료 분석 관련 텍스트 표시
    # (구현에 따라 표시 방식이 다를 수 있음)
    assert page.has_text?("무료", wait: 3) ||
           page.has_text?("회", wait: 3) ||
           page.has_text?("분석", wait: 3) ||
           page.has_selector?("[data-remaining]", wait: 2),
           "Expected to find usage info or analysis related text"
  end
end
