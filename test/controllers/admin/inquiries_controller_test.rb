# frozen_string_literal: true

require "test_helper"

class Admin::InquiriesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin)
    @user = users(:one)
    @inquiry = inquiries(:bug_inquiry)
    @pending_inquiry = inquiries(:bug_inquiry)
    @resolved_inquiry = inquiries(:improvement_inquiry)
  end

  # =========================================
  # 인증/권한 테스트
  # =========================================

  test "requires admin for index" do
    get admin_inquiries_path
    # Admin::BaseController의 require_admin이 root_path로 리다이렉트
    assert_redirected_to root_path
  end

  test "rejects non-admin user for index" do
    log_in_as(@user)

    get admin_inquiries_path
    assert_redirected_to root_path
    assert_flash :alert, "관리자 권한"
  end

  test "allows admin for index" do
    log_in_as(@admin)

    get admin_inquiries_path
    assert_response :success
  end

  # =========================================
  # GET /admin/inquiries - 목록
  # =========================================

  test "index shows all inquiries with stats" do
    log_in_as(@admin)

    get admin_inquiries_path
    assert_response :success
  end

  test "index filters by status" do
    log_in_as(@admin)

    get admin_inquiries_path, params: { status: "pending" }
    assert_response :success
  end

  test "index filters by category" do
    log_in_as(@admin)

    get admin_inquiries_path, params: { category: "bug" }
    assert_response :success
  end

  test "index paginates results" do
    log_in_as(@admin)

    get admin_inquiries_path, params: { page: 1 }
    assert_response :success
  end

  # =========================================
  # GET /admin/inquiries/:id - 상세
  # =========================================

  test "show displays inquiry details" do
    log_in_as(@admin)

    get admin_inquiry_path(@inquiry)
    assert_response :success
  end

  test "show requires admin" do
    log_in_as(@user)

    get admin_inquiry_path(@inquiry)
    assert_redirected_to root_path
  end

  # =========================================
  # PATCH /admin/inquiries/:id - 업데이트
  # =========================================

  test "update changes status" do
    log_in_as(@admin)

    patch admin_inquiry_path(@pending_inquiry), params: {
      inquiry: { status: "in_progress" }
    }

    assert_redirected_to admin_inquiry_path(@pending_inquiry)
    @pending_inquiry.reload
    assert_equal "in_progress", @pending_inquiry.status
  end

  test "update with admin response marks as resolved" do
    log_in_as(@admin)

    patch admin_inquiry_path(@pending_inquiry), params: {
      inquiry: { admin_response: "답변 내용입니다." }
    }

    assert_redirected_to admin_inquiry_path(@pending_inquiry)
    @pending_inquiry.reload
    assert_equal "resolved", @pending_inquiry.status
    assert_equal "답변 내용입니다.", @pending_inquiry.admin_response
    assert_equal @admin, @pending_inquiry.responded_by
  end

  test "update creates notification for user" do
    log_in_as(@admin)

    # feature_inquiry는 아직 답변이 없는 문의
    unanswered_inquiry = inquiries(:feature_inquiry)

    assert_difference("Notification.count", 1) do
      patch admin_inquiry_path(unanswered_inquiry), params: {
        inquiry: { admin_response: "답변 드립니다." }
      }
    end
  end

  test "update rejects invalid status" do
    log_in_as(@admin)

    patch admin_inquiry_path(@pending_inquiry), params: {
      inquiry: { status: "invalid_status" }
    }

    assert_redirected_to admin_inquiry_path(@pending_inquiry)
    assert_flash :alert
  end

  test "update requires admin" do
    log_in_as(@user)

    patch admin_inquiry_path(@pending_inquiry), params: {
      inquiry: { status: "in_progress" }
    }

    assert_redirected_to root_path
    @pending_inquiry.reload
    assert_equal "pending", @pending_inquiry.status
  end
end
