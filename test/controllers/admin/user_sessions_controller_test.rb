# frozen_string_literal: true

require "test_helper"

class Admin::UserSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user = users(:one)

    # 관리자 로그인 (비밀번호: test1234)
    post login_path, params: { email: @admin.email, password: "test1234" }
  end

  # ==========================================================================
  # index 테스트
  # ==========================================================================
  test "should get index" do
    # 테스트 세션 생성
    UserSession.record_login(user: @user, method: "email", ip_address: "192.168.1.1")
    UserSession.record_login(user: @admin, method: "google")

    get admin_user_sessions_path

    assert_response :success
    assert_select "table"
  end

  test "should filter by status active" do
    active = UserSession.record_login(user: @user, method: "email")
    ended = UserSession.record_login(user: @user, method: "google")
    ended.end_session!(reason: "user_initiated")

    get admin_user_sessions_path(status: "active")

    assert_response :success
  end

  test "should filter by status ended" do
    active = UserSession.record_login(user: @user, method: "email")
    ended = UserSession.record_login(user: @user, method: "google")
    ended.end_session!(reason: "user_initiated")

    get admin_user_sessions_path(status: "ended")

    assert_response :success
  end

  test "should filter by login method" do
    UserSession.record_login(user: @user, method: "email")
    UserSession.record_login(user: @user, method: "google")

    get admin_user_sessions_path(method: "email")

    assert_response :success
  end

  test "should filter by date range" do
    session = UserSession.record_login(user: @user, method: "email")
    session.update!(logged_in_at: 1.week.ago)

    get admin_user_sessions_path(from_date: 2.days.ago.to_date.to_s, to_date: Date.today.to_s)

    assert_response :success
  end

  test "should search by user name or email" do
    UserSession.record_login(user: @user, method: "email")

    get admin_user_sessions_path(q: @user.name[0..3])

    assert_response :success
  end

  # ==========================================================================
  # active 테스트
  # ==========================================================================
  test "should get active sessions" do
    UserSession.record_login(user: @user, method: "email")

    get active_admin_user_sessions_path

    assert_response :success
  end

  # ==========================================================================
  # force_logout 테스트
  # ==========================================================================
  test "should force logout an active session" do
    session = UserSession.record_login(user: @user, method: "email")

    assert_difference "AdminViewLog.count", 1 do
      post force_logout_admin_user_session_path(session)
    end

    assert_redirected_to admin_user_sessions_path
    assert_not session.reload.active?
    assert_equal "admin_action", session.logout_reason
  end

  test "should not force logout an already ended session" do
    session = UserSession.record_login(user: @user, method: "email")
    session.end_session!(reason: "user_initiated")

    post force_logout_admin_user_session_path(session)

    assert_redirected_to admin_user_sessions_path
    assert_equal "이미 종료된 세션입니다.", flash[:alert]
    assert_equal "user_initiated", session.reload.logout_reason  # 원래 사유 유지
  end

  # ==========================================================================
  # export 테스트
  # ==========================================================================
  test "should export sessions to CSV" do
    UserSession.record_login(user: @user, method: "email", ip_address: "192.168.1.1")
    UserSession.record_login(user: @user, method: "google")

    get export_admin_user_sessions_path(format: :csv)

    assert_response :success
    assert_equal "text/csv; charset=utf-8", response.content_type
    assert_match "user_sessions_", response.headers["Content-Disposition"]
  end

  # ==========================================================================
  # 권한 테스트
  # ==========================================================================
  test "should redirect non-admin users" do
    # 로그아웃
    delete logout_path

    # 일반 사용자로 로그인 (비밀번호: test1234)
    post login_path, params: { email: @user.email, password: "test1234" }

    get admin_user_sessions_path

    assert_redirected_to root_path
  end

  test "should redirect non-logged-in users" do
    delete logout_path

    get admin_user_sessions_path

    assert_redirected_to root_path
  end
end
