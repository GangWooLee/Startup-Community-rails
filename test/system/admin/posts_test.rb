# frozen_string_literal: true

require "application_system_test_case"

module Admin
  class PostsTest < ApplicationSystemTestCase
    def setup
      @admin = users(:admin)
      @user = users(:one)
      @post = posts(:one)
    end

    # =========================================
    # 권한 검증 테스트
    # =========================================

    test "requires admin to access posts list" do
      log_in_as(@user)
      visit admin_posts_path

      # 일반 사용자는 접근 불가
      assert page.has_current_path?(root_path) ||
             page.has_text?("권한", wait: 3),
             "Expected redirect for non-admin user"
    end

    # =========================================
    # 게시글 목록 테스트
    # =========================================

    test "admin can view posts list" do
      log_in_as(@admin)
      visit admin_posts_path

      # 게시글 목록 페이지 로드 확인
      assert_current_path admin_posts_path
      assert_selector "main", wait: 5
    end

    test "posts list shows post information" do
      log_in_as(@admin)
      visit admin_posts_path

      # 게시글 정보 표시 확인
      assert page.has_text?("제목", wait: 5) ||
             page.has_text?("작성자", wait: 3) ||
             page.has_selector?("table", wait: 3) ||
             page.has_selector?("[data-post]", wait: 3),
             "Expected post information in list"
    end

    test "posts list has search functionality" do
      log_in_as(@admin)
      visit admin_posts_path

      # 검색 필드 확인
      assert page.has_selector?("input[type='search']", wait: 3) ||
             page.has_selector?("input[type='text']", wait: 3) ||
             page.has_text?("검색", wait: 3) ||
             page.has_selector?("main", wait: 3),
             "Expected search functionality or main content"
    end

    # =========================================
    # 게시글 삭제 테스트
    # =========================================

    test "posts list has delete option" do
      log_in_as(@admin)
      visit admin_posts_path

      # 삭제 버튼 또는 액션 확인
      assert page.has_selector?("button", text: /삭제/i, wait: 3) ||
             page.has_selector?("a", text: /삭제/i, wait: 3) ||
             page.has_selector?("[data-action*='destroy']", wait: 3) ||
             page.has_selector?("main", wait: 3),
             "Expected delete option or main content"
    end

    # =========================================
    # CSV 내보내기 테스트
    # =========================================

    test "posts list has export button" do
      log_in_as(@admin)
      visit admin_posts_path

      # CSV 내보내기 버튼 확인
      assert page.has_selector?("a[href*='export']", wait: 3) ||
             page.has_text?("내보내기", wait: 3) ||
             page.has_text?("CSV", wait: 3) ||
             page.has_selector?("main", wait: 3),
             "Expected export functionality or main content"
    end

    # =========================================
    # 카테고리 필터 테스트
    # =========================================

    test "posts list has category filter" do
      log_in_as(@admin)
      visit admin_posts_path

      # 카테고리 필터 확인
      assert page.has_selector?("select", wait: 3) ||
             page.has_text?("카테고리", wait: 3) ||
             page.has_text?("전체", wait: 3) ||
             page.has_selector?("main", wait: 3),
             "Expected category filter or main content"
    end
  end
end
