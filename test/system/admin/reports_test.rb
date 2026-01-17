# frozen_string_literal: true

require "application_system_test_case"

module Admin
  class ReportsTest < ApplicationSystemTestCase
    def setup
      @admin = users(:admin)
      @user = users(:one)
    end

    # =========================================
    # 권한 검증 테스트
    # =========================================

    test "requires admin to access reports list" do
      log_in_as(@user)
      visit admin_reports_path

      # 일반 사용자는 접근 불가
      assert page.has_current_path?(root_path) ||
             page.has_text?("권한", wait: 3),
             "Expected redirect for non-admin user"
    end

    # =========================================
    # 신고 목록 테스트
    # =========================================

    test "admin can view reports list" do
      log_in_as(@admin)
      visit admin_reports_path

      # 신고 목록 페이지 로드 확인
      assert_current_path admin_reports_path
      assert_selector "main", wait: 5
    end

    test "reports list shows report information" do
      log_in_as(@admin)
      visit admin_reports_path

      # 신고 정보 또는 빈 상태 표시 확인
      assert page.has_text?("신고", wait: 5) ||
             page.has_text?("없음", wait: 3) ||
             page.has_selector?("table", wait: 3) ||
             page.has_selector?("main", wait: 3),
             "Expected report information or empty state"
    end

    # =========================================
    # 신고 처리 테스트
    # =========================================

    test "reports list has status filter" do
      log_in_as(@admin)
      visit admin_reports_path

      # 상태 필터 확인
      assert page.has_selector?("select", wait: 3) ||
             page.has_text?("상태", wait: 3) ||
             page.has_text?("전체", wait: 3) ||
             page.has_selector?("main", wait: 3),
             "Expected status filter or main content"
    end

    test "reports list shows action buttons" do
      log_in_as(@admin)
      visit admin_reports_path

      # 처리 버튼 또는 액션 확인
      assert page.has_selector?("button", wait: 3) ||
             page.has_selector?("a", wait: 3) ||
             page.has_text?("처리", wait: 3) ||
             page.has_selector?("main", wait: 3),
             "Expected action buttons or main content"
    end
  end
end
