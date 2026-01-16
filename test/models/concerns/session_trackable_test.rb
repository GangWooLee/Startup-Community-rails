# frozen_string_literal: true

require "test_helper"

class SessionTrackableTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    # 기존 세션 정리
    @user.user_sessions.destroy_all
  end

  test "user has_many user_sessions" do
    assert_respond_to @user, :user_sessions
    assert_kind_of ActiveRecord::Associations::CollectionProxy, @user.user_sessions
  end

  test "active_sessions returns only active sessions" do
    active1 = UserSession.record_login(user: @user, method: "email")
    active2 = UserSession.record_login(user: @user, method: "google")
    ended = UserSession.record_login(user: @user, method: "github")
    ended.end_session!(reason: "user_initiated")

    active = @user.active_sessions

    assert_includes active, active1
    assert_includes active, active2
    assert_not_includes active, ended
    assert_equal 2, active.count
  end

  test "session_history returns recent sessions" do
    3.times { UserSession.record_login(user: @user, method: "email") }

    history = @user.session_history(limit: 2)

    assert_equal 2, history.count
  end

  test "has_active_session? returns true when active session exists" do
    assert_not @user.has_active_session?

    UserSession.record_login(user: @user, method: "email")

    assert @user.has_active_session?
  end

  test "end_all_sessions! ends all active sessions" do
    session1 = UserSession.record_login(user: @user, method: "email")
    session2 = UserSession.record_login(user: @user, method: "google")

    assert_equal 2, @user.active_sessions.count

    @user.end_all_sessions!(reason: "admin_action")

    assert_equal 0, @user.active_sessions.count
    assert_equal "admin_action", session1.reload.logout_reason
    assert_equal "admin_action", session2.reload.logout_reason
  end

  test "end_other_sessions! ends all except specified session" do
    session1 = UserSession.record_login(user: @user, method: "email")
    session2 = UserSession.record_login(user: @user, method: "google")
    session3 = UserSession.record_login(user: @user, method: "github")

    @user.end_other_sessions!(except_token: session1.session_token)

    assert session1.reload.active?
    assert_not session2.reload.active?
    assert_not session3.reload.active?
    assert_equal 1, @user.active_sessions.count
  end

  test "login_count returns total logins" do
    3.times { UserSession.record_login(user: @user, method: "email") }

    assert_equal 3, @user.login_count
  end

  test "login_count with since filter" do
    old_session = UserSession.record_login(user: @user, method: "email")
    old_session.update!(logged_in_at: 10.days.ago)

    recent_session = UserSession.record_login(user: @user, method: "google")

    assert_equal 2, @user.login_count
    assert_equal 1, @user.login_count(since: 7.days.ago)
  end

  test "last_login_at returns most recent login time" do
    session1 = UserSession.record_login(user: @user, method: "email")
    session1.update!(logged_in_at: 2.days.ago)

    session2 = UserSession.record_login(user: @user, method: "google")
    session2.update!(logged_in_at: 1.day.ago)

    assert_equal session2.logged_in_at.to_i, @user.last_login_at.to_i
  end

  test "primary_login_method returns most used method" do
    3.times { UserSession.record_login(user: @user, method: "email") }
    1.times { UserSession.record_login(user: @user, method: "google") }

    assert_equal "email", @user.primary_login_method
  end

  test "recent_device_types returns unique device types" do
    UserSession.record_login(user: @user, method: "email", user_agent: "Mozilla/5.0 (Windows NT 10.0)")
    UserSession.record_login(user: @user, method: "email", user_agent: "Mozilla/5.0 (iPhone)")
    UserSession.record_login(user: @user, method: "email", user_agent: "Mozilla/5.0 (Windows NT 10.0)")

    devices = @user.recent_device_types

    assert_includes devices, "desktop"
    assert_includes devices, "mobile"
    assert_equal 2, devices.size
  end

  test "recent_ip_addresses returns unique IPs" do
    UserSession.record_login(user: @user, method: "email", ip_address: "192.168.1.1")
    UserSession.record_login(user: @user, method: "email", ip_address: "192.168.1.2")
    UserSession.record_login(user: @user, method: "email", ip_address: "192.168.1.1")

    ips = @user.recent_ip_addresses

    assert_includes ips, "192.168.1.1"
    assert_includes ips, "192.168.1.2"
  end

  test "user_sessions association has dependent destroy" do
    # User 모델의 has_many :user_sessions, dependent: :destroy 확인
    reflection = User.reflect_on_association(:user_sessions)
    assert_equal :destroy, reflection.options[:dependent]
  end
end
