# frozen_string_literal: true

require "test_helper"

class LoginSecurityTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    # Clear ALL cache to avoid test interference
    # Integration tests use 127.0.0.1 as remote_ip
    Rails.cache.clear
  end

  teardown do
    # Clean up cache after each test
    Rails.cache.clear
  end

  test "successful login clears failed attempts" do
    # First, set some failed attempts directly in cache
    Rails.cache.write("login_attempts:127.0.0.1", 3, expires_in: 10.minutes)

    # Verify attempts exist
    attempts = Rails.cache.read("login_attempts:127.0.0.1")
    assert_equal 3, attempts.to_i

    # Successful login should clear attempts (fixture password is 'test1234')
    post login_path, params: { email: @user.email, password: "test1234" }
    assert_redirected_to community_path

    # Attempts should be cleared
    assert_nil Rails.cache.read("login_attempts:127.0.0.1")
  end

  test "failed login increments attempt counter" do
    # First failed login
    post login_path, params: { email: @user.email, password: "wrongpassword" }
    assert_response :unprocessable_entity

    # Check attempts were tracked (the concern writes to cache)
    attempts = Rails.cache.read("login_attempts:127.0.0.1")
    assert_operator attempts.to_i, :>=, 1, "Failed login should track attempts"
  end

  test "failed login with non-existent user also tracks attempts" do
    post login_path, params: { email: "nonexistent@example.com", password: "wrongpassword" }
    assert_response :unprocessable_entity

    # Check attempts were tracked
    attempts = Rails.cache.read("login_attempts:127.0.0.1")
    assert_operator attempts.to_i, :>=, 1, "Failed login with non-existent user should track attempts"
  end

  test "account gets locked after max failed attempts" do
    # Make 5 failed attempts (MAX_FAILED_ATTEMPTS)
    # The lockout is set AFTER the 5th failed attempt, on the same request
    # So the 5th request still returns unprocessable_entity but sets the lockout flag
    5.times do |i|
      post login_path, params: { email: @user.email, password: "wrongpassword" }
      assert_response :unprocessable_entity, "Attempt #{i + 1} should fail with unprocessable_entity"
    end

    # Account should now be locked (set after the 5th failed attempt)
    locked = Rails.cache.read("login_lockout:127.0.0.1")
    assert locked, "Account should be locked after 5 failed attempts"

    # The 6th attempt should be blocked with redirect
    post login_path, params: { email: @user.email, password: "wrongpassword" }
    assert_redirected_to login_path, "6th attempt should redirect due to lockout"
  end

  test "locked account cannot login even with correct password" do
    # Lock the account manually
    Rails.cache.write("login_lockout:127.0.0.1", true, expires_in: 15.minutes)

    # Try to login with correct password (fixture uses 'test1234')
    post login_path, params: { email: @user.email, password: "test1234" }

    # Should be blocked (redirect to login with flash message)
    assert_redirected_to login_path
    follow_redirect!
    assert_match /잠겼습니다/, flash[:alert]
  end

  # ===== 잠금 해제 테스트 추가 (2026-01-17) =====

  test "lockout expires after 15 minutes" do
    # Lock the account
    Rails.cache.write("login_lockout:127.0.0.1", true, expires_in: 15.minutes)
    Rails.cache.write("login_attempts:127.0.0.1", 5, expires_in: 10.minutes)

    # Verify locked
    assert Rails.cache.read("login_lockout:127.0.0.1"), "Account should be locked initially"

    # Travel forward 16 minutes (beyond 15 minute lockout)
    travel 16.minutes do
      # Cache should have expired
      assert_nil Rails.cache.read("login_lockout:127.0.0.1"), "Lockout should expire after 15 minutes"

      # Should be able to login again
      post login_path, params: { email: @user.email, password: "test1234" }
      assert_redirected_to community_path, "Should be able to login after lockout expires"
    end
  end

  test "failed attempts counter expires after window" do
    # Make 3 failed attempts
    3.times do
      post login_path, params: { email: @user.email, password: "wrongpassword" }
      assert_response :unprocessable_entity
    end

    # Verify attempts were tracked
    attempts = Rails.cache.read("login_attempts:127.0.0.1")
    assert_equal 3, attempts.to_i

    # Travel forward 11 minutes (beyond 10 minute window)
    travel 11.minutes do
      # Attempt counter should have expired
      assert_nil Rails.cache.read("login_attempts:127.0.0.1"), "Attempt counter should expire after window"

      # Make 2 more failed attempts (should not lock since counter reset)
      2.times do
        post login_path, params: { email: @user.email, password: "wrongpassword" }
        assert_response :unprocessable_entity
      end

      # Should NOT be locked (only 2 new attempts after reset)
      locked = Rails.cache.read("login_lockout:127.0.0.1")
      assert_nil locked, "Account should not be locked with only 2 attempts after reset"
    end
  end

  test "lockout message shows remaining time" do
    # Lock the account
    Rails.cache.write("login_lockout:127.0.0.1", true, expires_in: 15.minutes)

    # Try to login
    post login_path, params: { email: @user.email, password: "test1234" }
    assert_redirected_to login_path

    follow_redirect!
    # Should mention minutes remaining
    assert_match /분 후/, flash[:alert], "Flash should mention minutes remaining"
  end

  test "successful login after lockout expiry clears all cache" do
    # Lock the account and set attempts
    Rails.cache.write("login_lockout:127.0.0.1", true, expires_in: 15.minutes)
    Rails.cache.write("login_attempts:127.0.0.1", 5, expires_in: 10.minutes)

    # Travel past lockout period
    travel 16.minutes do
      # Login successfully
      post login_path, params: { email: @user.email, password: "test1234" }
      assert_redirected_to community_path

      # All cache entries should be cleared
      assert_nil Rails.cache.read("login_lockout:127.0.0.1")
      assert_nil Rails.cache.read("login_attempts:127.0.0.1")
    end
  end
end
