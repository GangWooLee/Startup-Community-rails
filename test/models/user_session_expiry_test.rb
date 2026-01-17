# frozen_string_literal: true

require "test_helper"

class UserSessionExpiryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @admin = users(:admin) # Assuming there's an admin fixture
  end

  test "regular user session is not expired within timeout period" do
    session = UserSession.record_login(
      user: @user,
      method: "email",
      ip_address: "127.0.0.1",
      user_agent: "Test Agent"
    )

    # Update last_activity_at to 6 hours ago (within 12-hour timeout)
    session.update_column(:last_activity_at, 6.hours.ago)

    refute session.expired?, "Session should not be expired within timeout period"
  end

  test "regular user session is expired after timeout period" do
    session = UserSession.record_login(
      user: @user,
      method: "email",
      ip_address: "127.0.0.1",
      user_agent: "Test Agent"
    )

    # Update last_activity_at to 13 hours ago (beyond 12-hour timeout)
    session.update_column(:last_activity_at, 13.hours.ago)

    assert session.expired?, "Session should be expired after timeout period"
  end

  test "admin session has shorter timeout (30 minutes)" do
    # Make user an admin
    @user.update!(is_admin: true)

    session = UserSession.record_login(
      user: @user,
      method: "email",
      ip_address: "127.0.0.1",
      user_agent: "Test Agent"
    )

    # Update last_activity_at to 20 minutes ago (within 30-minute timeout)
    session.update_column(:last_activity_at, 20.minutes.ago)
    refute session.expired?, "Admin session should not be expired within 30 minutes"

    # Update last_activity_at to 35 minutes ago (beyond 30-minute timeout)
    session.update_column(:last_activity_at, 35.minutes.ago)
    assert session.expired?, "Admin session should be expired after 30 minutes"
  end

  test "ended session is never expired" do
    session = UserSession.record_login(
      user: @user,
      method: "email",
      ip_address: "127.0.0.1",
      user_agent: "Test Agent"
    )

    session.end_session!(reason: "user_initiated")

    # Even if last_activity_at is old, ended session should not be "expired"
    session.update_column(:last_activity_at, 100.hours.ago)

    refute session.expired?, "Ended session should not be considered expired"
  end

  test "expire_if_needed! ends expired session" do
    session = UserSession.record_login(
      user: @user,
      method: "email",
      ip_address: "127.0.0.1",
      user_agent: "Test Agent"
    )

    # Make session expired
    session.update_column(:last_activity_at, 13.hours.ago)

    assert session.expire_if_needed!
    session.reload

    refute session.active?, "Session should be ended"
    assert_equal "session_expired", session.logout_reason
  end

  test "expire_if_needed! returns false for non-expired session" do
    session = UserSession.record_login(
      user: @user,
      method: "email",
      ip_address: "127.0.0.1",
      user_agent: "Test Agent"
    )

    refute session.expire_if_needed!
    session.reload

    assert session.active?, "Session should still be active"
  end

  test "expires_in returns remaining time" do
    session = UserSession.record_login(
      user: @user,
      method: "email",
      ip_address: "127.0.0.1",
      user_agent: "Test Agent"
    )

    # Set last_activity_at to 6 hours ago
    session.update_column(:last_activity_at, 6.hours.ago)

    remaining = session.expires_in
    # Should be approximately 6 hours (12 - 6)
    assert_in_delta 6.hours.to_i, remaining.to_i, 60 # Allow 1 minute tolerance
  end

  test "touch_activity! updates last_activity_at" do
    session = UserSession.record_login(
      user: @user,
      method: "email",
      ip_address: "127.0.0.1",
      user_agent: "Test Agent"
    )

    old_activity = session.last_activity_at

    travel 1.minute do
      session.touch_activity!
      session.reload

      assert session.last_activity_at > old_activity, "last_activity_at should be updated"
    end
  end
end
