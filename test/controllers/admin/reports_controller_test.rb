# frozen_string_literal: true

require "test_helper"

class Admin::ReportsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
    @user = users(:one)
    @report = reports(:post_spam_report)
    @pending_report = reports(:post_spam_report)
    @resolved_report = reports(:post_scam_report)
  end

  # =========================================
  # 인증/권한 테스트
  # =========================================

  test "requires admin for index" do
    get admin_reports_path
    # Admin::BaseController의 require_admin이 root_path로 리다이렉트
    assert_redirected_to root_path
  end

  test "rejects non-admin user for index" do
    log_in_as(@user)

    get admin_reports_path
    assert_redirected_to root_path
    assert_flash :alert, "관리자 권한"
  end

  test "allows admin for index" do
    log_in_as(@admin)

    get admin_reports_path
    assert_response :success
  end

  # =========================================
  # GET /admin/reports - 목록
  # =========================================

  test "index shows all reports with stats" do
    log_in_as(@admin)

    get admin_reports_path
    assert_response :success
  end

  test "index filters by status" do
    log_in_as(@admin)

    get admin_reports_path, params: { status: "pending" }
    assert_response :success
  end

  test "index filters by type" do
    log_in_as(@admin)

    get admin_reports_path, params: { type: "Post" }
    assert_response :success
  end

  test "index paginates results" do
    log_in_as(@admin)

    get admin_reports_path, params: { page: 1 }
    assert_response :success
  end

  # =========================================
  # GET /admin/reports/:id - 상세
  # =========================================

  test "show displays report details" do
    log_in_as(@admin)

    get admin_report_path(@report)
    assert_response :success
  end

  test "show requires admin" do
    log_in_as(@user)

    get admin_report_path(@report)
    assert_redirected_to root_path
  end

  # =========================================
  # PATCH /admin/reports/:id - 업데이트
  # =========================================

  test "update changes status to resolved" do
    log_in_as(@admin)

    patch admin_report_path(@pending_report), params: {
      report: {
        status: "resolved",
        admin_note: "처리 완료"
      }
    }

    assert_redirected_to admin_report_path(@pending_report)
    @pending_report.reload
    assert_equal "resolved", @pending_report.status
    assert_equal "처리 완료", @pending_report.admin_note
    assert_equal @admin, @pending_report.resolved_by
  end

  test "update changes status to dismissed" do
    log_in_as(@admin)

    patch admin_report_path(@pending_report), params: {
      report: {
        status: "dismissed",
        admin_note: "사유에 해당하지 않음"
      }
    }

    assert_redirected_to admin_report_path(@pending_report)
    @pending_report.reload
    assert_equal "dismissed", @pending_report.status
  end

  test "update changes status to reviewed" do
    log_in_as(@admin)

    patch admin_report_path(@pending_report), params: {
      report: {
        status: "reviewed",
        admin_note: "검토 중"
      }
    }

    assert_redirected_to admin_report_path(@pending_report)
    @pending_report.reload
    assert_equal "reviewed", @pending_report.status
  end

  test "update rejects invalid status" do
    log_in_as(@admin)

    patch admin_report_path(@pending_report), params: {
      report: { status: "invalid_status" }
    }

    assert_redirected_to admin_report_path(@pending_report)
    assert_flash :alert
    @pending_report.reload
    assert_equal "pending", @pending_report.status
  end

  test "update requires admin" do
    log_in_as(@user)

    patch admin_report_path(@pending_report), params: {
      report: { status: "resolved" }
    }

    assert_redirected_to root_path
    @pending_report.reload
    assert_equal "pending", @pending_report.status
  end
end
