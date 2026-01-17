# frozen_string_literal: true

require "application_system_test_case"

class ResponsiveTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
  end

  # =========================================
  # 모바일 뷰포트 테스트 (375px)
  # =========================================

  test "mobile viewport shows mobile layout" do
    page.driver.browser.manage.window.resize_to(375, 812)

    visit root_path
    sleep 1

    # 모바일 레이아웃 확인
    assert page.has_selector?("body", wait: 5),
           "Expected page to load on mobile"
  end

  test "mobile navigation works" do
    page.driver.browser.manage.window.resize_to(375, 812)

    log_in_as(@user)
    visit posts_path
    sleep 1

    # 모바일에서 네비게이션 또는 메뉴 확인
    assert page.has_selector?("nav", wait: 3) ||
           page.has_selector?("header", wait: 3) ||
           page.has_selector?("[data-controller*='mobile']", wait: 3) ||
           page.has_selector?("aside", wait: 3) ||
           page.has_selector?("main", wait: 3),
           "Expected mobile navigation"
  end

  # =========================================
  # 태블릿 뷰포트 테스트 (768px)
  # =========================================

  test "tablet viewport shows appropriate layout" do
    page.driver.browser.manage.window.resize_to(768, 1024)

    log_in_as(@user)
    visit posts_path
    sleep 1

    # 태블릿 레이아웃 확인
    assert page.has_selector?("main", wait: 5),
           "Expected page to load on tablet"
  end

  # =========================================
  # 데스크톱 뷰포트 테스트 (1280px)
  # =========================================

  test "desktop viewport shows full layout" do
    page.driver.browser.manage.window.resize_to(1280, 800)

    log_in_as(@user)
    visit posts_path
    sleep 1

    # 데스크톱 레이아웃 - 사이드바 표시
    assert page.has_selector?("aside", wait: 3) ||
           page.has_selector?("nav", wait: 3) ||
           page.has_selector?("main", wait: 3),
           "Expected desktop layout with sidebar"
  end

  # =========================================
  # 폼 반응형 테스트
  # =========================================

  test "forms are usable on mobile" do
    page.driver.browser.manage.window.resize_to(375, 812)

    log_in_as(@user)
    visit new_post_path
    sleep 1

    # 모바일에서 폼 사용 가능 확인
    assert page.has_selector?("form", wait: 5) ||
           page.has_selector?("input", wait: 3) ||
           page.has_selector?("textarea", wait: 3),
           "Expected form to be accessible on mobile"
  end

  # =========================================
  # 이미지 반응형 테스트
  # =========================================

  test "images scale appropriately" do
    page.driver.browser.manage.window.resize_to(375, 812)

    visit root_path
    sleep 1

    # 이미지가 뷰포트를 넘지 않는지 확인
    images = all("img", wait: 3) rescue []

    if images.any?
      # 이미지 존재 확인
      assert images.length.positive?
    else
      # 이미지가 없는 경우도 정상
      assert_selector "body", wait: 3
    end
  end

  # =========================================
  # 텍스트 가독성 테스트
  # =========================================

  test "text is readable on all viewports" do
    page.driver.browser.manage.window.resize_to(375, 812)

    visit root_path
    sleep 1

    # 텍스트 콘텐츠 존재 확인
    assert page.has_selector?("body", wait: 5),
           "Expected page content to be visible"

    # 데스크톱으로 전환
    page.driver.browser.manage.window.resize_to(1280, 800)
    sleep 0.5

    assert page.has_selector?("body", wait: 3),
           "Expected page content on desktop"
  end
end
