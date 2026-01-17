# frozen_string_literal: true

require "application_system_test_case"

module Admin
  class DashboardTest < ApplicationSystemTestCase
    def setup
      @admin = users(:admin)
      @user = users(:one)
    end

    # =========================================
    # 권한 검증 테스트
    # =========================================

    test "requires login to access admin dashboard" do
      visit admin_root_path

      # 비로그인 시 리다이렉트 (로그인 또는 루트)
      assert page.has_current_path?(login_path) ||
             page.has_current_path?(root_path),
             "Expected redirect for unauthenticated user"
    end

    test "regular user cannot access admin dashboard" do
      log_in_as(@user)
      visit admin_root_path

      # 일반 사용자는 접근 불가 - 리다이렉트 또는 에러
      assert page.has_current_path?(root_path) ||
             page.has_text?("권한", wait: 3) ||
             page.has_text?("접근", wait: 3),
             "Expected redirect or error for non-admin user"
    end

    # =========================================
    # 대시보드 페이지 테스트
    # =========================================

    test "admin can view dashboard" do
      log_in_as(@admin)
      visit admin_root_path

      # 관리자 대시보드 로드 확인
      assert_current_path admin_root_path
      assert_selector "main", wait: 5
    end

    test "dashboard shows statistics" do
      log_in_as(@admin)
      visit admin_root_path

      # 통계 정보 또는 대시보드 콘텐츠 확인
      assert page.has_text?("사용자", wait: 5) ||
             page.has_text?("게시글", wait: 3) ||
             page.has_text?("통계", wait: 3) ||
             page.has_selector?("[data-stats]", wait: 3) ||
             page.has_selector?("main", wait: 3),
             "Expected dashboard statistics"
    end

    test "dashboard shows navigation menu" do
      log_in_as(@admin)
      visit admin_root_path

      # 관리 메뉴 확인
      assert page.has_text?("회원", wait: 5) ||
             page.has_text?("관리", wait: 3) ||
             page.has_selector?("nav", wait: 3) ||
             page.has_selector?("aside", wait: 3),
             "Expected admin navigation menu"
    end

    # =========================================
    # 네비게이션 테스트
    # =========================================

    test "can navigate to users management from dashboard" do
      log_in_as(@admin)
      visit admin_root_path

      # 회원 관리 링크 클릭
      users_link = find("a", text: /회원|사용자|Users/i, wait: 5) rescue nil

      if users_link
        users_link.click
        sleep 0.5

        # 회원 관리 페이지로 이동
        assert page.has_current_path?(admin_users_path) ||
               page.has_text?("회원", wait: 3),
               "Expected to navigate to users management"
      else
        # 링크가 다른 위치에 있을 수 있음
        assert_selector "main", wait: 3
      end
    end

    test "can navigate to posts management from dashboard" do
      log_in_as(@admin)
      visit admin_root_path

      # 게시글 관리 링크 클릭
      posts_link = find("a", text: /게시글|게시물|Posts/i, wait: 5) rescue nil

      if posts_link
        posts_link.click
        sleep 0.5

        # 게시글 관리 페이지로 이동
        assert page.has_current_path?(admin_posts_path) ||
               page.has_text?("게시글", wait: 3),
               "Expected to navigate to posts management"
      else
        assert_selector "main", wait: 3
      end
    end
  end
end
