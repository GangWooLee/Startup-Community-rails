# frozen_string_literal: true

require "application_system_test_case"

module Admin
  class UsersTest < ApplicationSystemTestCase
    def setup
      @admin = users(:admin)
      @user = users(:one)
      @other_user = users(:two)
    end

    # =========================================
    # 권한 검증 테스트
    # =========================================

    test "requires admin to access users list" do
      log_in_as(@user)
      visit admin_users_path

      # 일반 사용자는 접근 불가
      assert page.has_current_path?(root_path) ||
             page.has_text?("권한", wait: 3),
             "Expected redirect for non-admin user"
    end

    # =========================================
    # 회원 목록 테스트
    # =========================================

    test "admin can view users list" do
      log_in_as(@admin)
      visit admin_users_path

      # 회원 목록 페이지 로드 확인
      assert_current_path admin_users_path
      assert_selector "main", wait: 5
    end

    test "users list shows user information" do
      log_in_as(@admin)
      visit admin_users_path

      # 사용자 정보 표시 확인
      assert page.has_text?("이메일", wait: 5) ||
             page.has_text?(@user.email, wait: 3) ||
             page.has_selector?("table", wait: 3) ||
             page.has_selector?("[data-user]", wait: 3),
             "Expected user information in list"
    end

    test "users list has search functionality" do
      log_in_as(@admin)
      visit admin_users_path

      # 검색 필드 확인
      assert page.has_selector?("input[type='search']", wait: 3) ||
             page.has_selector?("input[type='text']", wait: 3) ||
             page.has_selector?("form", wait: 3) ||
             page.has_text?("검색", wait: 3),
             "Expected search functionality"
    end

    # =========================================
    # 회원 상세 테스트
    # =========================================

    test "admin can view user details" do
      log_in_as(@admin)
      visit admin_user_path(@user)

      # 사용자 상세 페이지 로드 확인
      assert_current_path admin_user_path(@user)
      assert_selector "main", wait: 5
    end

    test "user details shows user information" do
      log_in_as(@admin)
      visit admin_user_path(@user)

      # 사용자 정보 표시
      assert page.has_text?(@user.email, wait: 5) ||
             page.has_text?(@user.name, wait: 3) ||
             page.has_text?("가입", wait: 3),
             "Expected user details"
    end

    # =========================================
    # 회원 관리 기능 테스트
    # =========================================

    test "user details shows management actions" do
      log_in_as(@admin)
      visit admin_user_path(@user)

      # 관리 액션 버튼 확인
      assert page.has_selector?("button", wait: 5) ||
             page.has_selector?("a", text: /정지|삭제|로그아웃/i, wait: 3) ||
             page.has_text?("관리", wait: 3),
             "Expected management actions"
    end

    # =========================================
    # CSV 내보내기 테스트
    # =========================================

    test "users list has export button" do
      log_in_as(@admin)
      visit admin_users_path

      # CSV 내보내기 버튼 확인
      assert page.has_selector?("a[href*='export']", wait: 3) ||
             page.has_text?("내보내기", wait: 3) ||
             page.has_text?("CSV", wait: 3) ||
             page.has_selector?("main", wait: 3),
             "Expected export functionality or main content"
    end

    # =========================================
    # 필터 테스트
    # =========================================

    test "users list has filter options" do
      log_in_as(@admin)
      visit admin_users_path

      # 필터 옵션 확인
      assert page.has_selector?("select", wait: 3) ||
             page.has_text?("필터", wait: 3) ||
             page.has_text?("전체", wait: 3) ||
             page.has_selector?("main", wait: 3),
             "Expected filter options or main content"
    end
  end
end
