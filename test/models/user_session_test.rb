# frozen_string_literal: true

require "test_helper"

class UserSessionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  # ==========================================================================
  # record_login 테스트
  # ==========================================================================
  test "record_login creates a new session with required attributes" do
    session = UserSession.record_login(
      user: @user,
      method: "email",
      ip_address: "192.168.1.100",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
      remember_me: true
    )

    assert session.persisted?
    assert_equal @user.id, session.user_id
    assert_equal "email", session.login_method
    assert_equal "192.168.1.100", session.ip_address
    assert session.remember_me
    assert session.session_token.present?
    assert session.logged_in_at.present?
    assert_nil session.logged_out_at
    assert session.active?
  end

  test "record_login parses device_type from user_agent" do
    # Desktop
    desktop_session = UserSession.record_login(
      user: @user,
      method: "email",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    )
    assert_equal "desktop", desktop_session.device_type

    # Mobile
    mobile_session = UserSession.record_login(
      user: @user,
      method: "google",
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0)"
    )
    assert_equal "mobile", mobile_session.device_type

    # Tablet
    tablet_session = UserSession.record_login(
      user: @user,
      method: "github",
      user_agent: "Mozilla/5.0 (iPad; CPU OS 14_0)"
    )
    assert_equal "tablet", tablet_session.device_type
  end

  test "record_login generates unique session_token" do
    session1 = UserSession.record_login(user: @user, method: "email")
    session2 = UserSession.record_login(user: @user, method: "email")

    assert_not_equal session1.session_token, session2.session_token
  end

  # ==========================================================================
  # end_session! 테스트
  # ==========================================================================
  test "end_session! sets logged_out_at and reason" do
    session = UserSession.record_login(user: @user, method: "email")
    assert session.active?

    session.end_session!(reason: "user_initiated")

    assert_not session.active?
    assert session.logged_out_at.present?
    assert_equal "user_initiated", session.logout_reason
  end

  test "end_session! with admin_action reason" do
    session = UserSession.record_login(user: @user, method: "google")
    session.end_session!(reason: "admin_action")

    assert_equal "admin_action", session.logout_reason
  end

  # ==========================================================================
  # Scopes 테스트
  # ==========================================================================
  test "active scope returns only sessions without logged_out_at" do
    active_session = UserSession.record_login(user: @user, method: "email")
    ended_session = UserSession.record_login(user: @user, method: "google")
    ended_session.end_session!(reason: "user_initiated")

    active_sessions = UserSession.active

    assert_includes active_sessions, active_session
    assert_not_includes active_sessions, ended_session
  end

  test "ended scope returns only sessions with logged_out_at" do
    active_session = UserSession.record_login(user: @user, method: "email")
    ended_session = UserSession.record_login(user: @user, method: "google")
    ended_session.end_session!(reason: "user_initiated")

    ended_sessions = UserSession.ended

    assert_not_includes ended_sessions, active_session
    assert_includes ended_sessions, ended_session
  end

  test "recent scope orders by logged_in_at desc" do
    old_session = UserSession.record_login(user: @user, method: "email")
    old_session.update!(logged_in_at: 1.day.ago)

    new_session = UserSession.record_login(user: @user, method: "google")

    sessions = UserSession.recent.limit(2)

    assert_equal new_session, sessions.first
    assert_equal old_session, sessions.second
  end

  test "by_login_method scope filters by method" do
    email_session = UserSession.record_login(user: @user, method: "email")
    google_session = UserSession.record_login(user: @user, method: "google")

    email_sessions = UserSession.by_login_method("email")

    assert_includes email_sessions, email_session
    assert_not_includes email_sessions, google_session
  end

  # ==========================================================================
  # Instance Methods 테스트
  # ==========================================================================
  test "duration_minutes returns nil for active session" do
    session = UserSession.record_login(user: @user, method: "email")

    assert_nil session.duration_minutes
  end

  test "duration_minutes calculates correctly for ended session" do
    session = UserSession.record_login(user: @user, method: "email")
    session.update!(logged_in_at: 30.minutes.ago)
    session.end_session!(reason: "user_initiated")

    # 약 30분 (테스트 실행 시간에 따라 약간의 오차)
    assert_in_delta 30, session.duration_minutes, 1
  end

  test "duration_formatted returns formatted string" do
    session = UserSession.record_login(user: @user, method: "email")
    assert_equal "활성 중", session.duration_formatted

    # 30분 세션
    session.update!(logged_in_at: 30.minutes.ago)
    session.end_session!(reason: "user_initiated")
    assert_match(/분/, session.duration_formatted)
  end

  test "masked_ip_address masks the last two octets" do
    session = UserSession.record_login(
      user: @user,
      method: "email",
      ip_address: "192.168.1.100"
    )

    assert_equal "192.168.***.***", session.masked_ip_address
  end

  test "masked_ip_address returns N/A for blank ip" do
    session = UserSession.record_login(user: @user, method: "email")

    assert_equal "N/A", session.masked_ip_address
  end

  test "touch_activity! updates last_activity_at" do
    session = UserSession.record_login(user: @user, method: "email")
    original_time = session.last_activity_at

    travel 1.minute do
      session.touch_activity!
      assert session.last_activity_at > original_time
    end
  end

  # ==========================================================================
  # Validations 테스트
  # ==========================================================================
  test "validates login_method inclusion" do
    session = UserSession.new(
      user: @user,
      login_method: "invalid_method"
    )

    assert_not session.valid?
    assert_includes session.errors[:login_method], "is not included in the list"
  end

  test "validates session_token uniqueness" do
    session1 = UserSession.record_login(user: @user, method: "email")

    session2 = UserSession.new(
      user: @user,
      login_method: "email",
      session_token: session1.session_token,
      logged_in_at: Time.current
    )

    assert_not session2.valid?
    assert_includes session2.errors[:session_token], "has already been taken"
  end
end
