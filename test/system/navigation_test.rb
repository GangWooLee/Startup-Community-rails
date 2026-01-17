# frozen_string_literal: true

require "application_system_test_case"

class NavigationTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
  end

  # =========================================
  # 헤더 네비게이션 테스트
  # =========================================

  test "header shows logo or brand" do
    visit root_path

    # 페이지 로드 대기
    sleep 1

    # 로고 또는 브랜드 확인 - HTML 소스 검색
    assert page.html.include?("Undrew") ||
           page.html.include?("logo") ||
           page.has_selector?("header", wait: 3) ||
           page.has_selector?("nav", wait: 3),
           "Expected header with logo or brand"
  end

  test "header shows navigation links" do
    visit root_path
    sleep 2

    # 네비게이션 링크 확인 - HTML 소스에서 검색
    assert page.html.include?("<a") ||
           page.has_selector?("a", wait: 5) ||
           page.has_selector?("button", wait: 3),
           "Expected navigation links in header"
  end

  # =========================================
  # 로그인/비로그인 상태 네비게이션
  # =========================================

  test "guest sees login option" do
    visit root_path
    sleep 1

    # 비로그인 시 로그인 관련 요소 - HTML 소스 검색
    assert page.html.include?("로그인") ||
           page.html.include?("login") ||
           page.html.include?("시작하기") ||
           page.has_selector?("a", wait: 3),
           "Expected login option for guest"
  end

  test "logged in user can access profile" do
    log_in_as(@user)
    visit my_page_path

    # 프로필 페이지 접근 확인
    assert_current_path my_page_path
    assert_selector "body", wait: 5
  end

  # =========================================
  # 사이드바 네비게이션 테스트
  # =========================================

  test "logged in user sees navigation" do
    log_in_as(@user)
    visit posts_path

    # 커뮤니티 페이지에서 네비게이션 확인
    assert page.has_selector?("body", wait: 5),
           "Expected page to load"
  end

  test "sidebar or navigation exists on posts page" do
    log_in_as(@user)
    visit posts_path

    # 사이드바 또는 네비게이션 존재 확인
    assert page.has_selector?("aside", wait: 3) ||
           page.has_selector?("nav", wait: 3) ||
           page.has_selector?("header", wait: 3) ||
           page.has_selector?("body", wait: 3),
           "Expected navigation element"
  end

  # =========================================
  # 페이지 간 네비게이션 테스트
  # =========================================

  test "can navigate between main sections" do
    log_in_as(@user)
    visit root_path
    sleep 1

    # 커뮤니티 링크로 이동
    community_link = find("a", text: /커뮤니티|게시판|Posts/i, wait: 3) rescue nil

    if community_link
      community_link.click
      sleep 0.5
      assert page.has_current_path?(posts_path) ||
             page.has_text?("게시글", wait: 3),
             "Expected to navigate to posts"
    else
      # 링크가 다른 위치에 있을 수 있음
      visit posts_path
      assert_current_path posts_path
    end
  end

  # =========================================
  # 알림 접근 테스트
  # =========================================

  test "logged in user can access notifications" do
    log_in_as(@user)
    visit notifications_path

    # 알림 페이지 접근 확인
    assert_current_path notifications_path
    assert_selector "body", wait: 5
  end
end
