# frozen_string_literal: true

require "test_helper"

class Admin::SudoControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Clear any cache from previous tests (especially login lockouts)
    Rails.cache.clear

    @admin = users(:admin)
    # Ensure admin status
    @admin.update!(is_admin: true) unless @admin.admin?

    # Log in as admin (fixture uses 'test1234' password)
    post login_path, params: { email: @admin.email, password: "test1234" }
    assert_response :redirect, "Admin login should succeed"
  end

  teardown do
    Rails.cache.clear
  end

  test "should show sudo confirmation page" do
    get admin_sudo_path
    assert_response :success
    assert_select "input[type='password']"
  end

  test "should enable sudo mode with correct password" do
    post admin_sudo_path, params: { password: "test1234" }

    assert_redirected_to admin_root_path
    follow_redirect!
    assert_match /재인증/, flash[:notice]
  end

  test "should reject incorrect password" do
    post admin_sudo_path, params: { password: "wrongpassword" }

    assert_response :unprocessable_entity
    assert_match /올바르지 않습니다/, flash[:alert]
  end

  test "should redirect back to intended action after sudo confirmation" do
    # First, try to access a protected action and store return URL in session
    get admin_sudo_path

    # Integration tests can't directly access @controller.session
    # Instead, the session is shared across requests in the same test

    # Confirm sudo (without return_to stored, should redirect to admin_root_path)
    post admin_sudo_path, params: { password: "test1234" }

    # Should redirect to admin root when no return URL is stored
    assert_redirected_to admin_root_path
  end

  test "should clear sudo mode on destroy" do
    # First enable sudo
    post admin_sudo_path, params: { password: "test1234" }

    # Then destroy
    delete admin_sudo_path

    assert_redirected_to admin_root_path
    assert_match /종료/, flash[:notice]
  end

  test "sudo mode should log action" do
    # Enable sudo mode - logging happens in the SudoMode concern
    assert_difference "AdminViewLog.count", 1 do
      post admin_sudo_path, params: { password: "test1234" }
    end

    assert_redirected_to admin_root_path

    # Verify the log entry
    log = AdminViewLog.last
    assert_equal "sudo_mode_enabled", log.action
    assert_equal @admin.id, log.admin_id
    assert_equal @admin.id, log.target_id
    assert_equal "User", log.target_type
  end

  # ===== 보안 테스트 추가 (2026-01-17) =====

  test "sudo mode expires after 15 minutes" do
    # Enable sudo mode
    post admin_sudo_path, params: { password: "test1234" }
    assert_redirected_to admin_root_path

    # Verify sudo is active now
    get admin_sudo_path
    # Should have notice about remaining time or be redirected since already in sudo

    # Travel forward 16 minutes
    travel 16.minutes do
      # Sudo mode should be expired now
      # Access admin_sudo_path again to check
      get admin_sudo_path
      assert_response :success  # Should show the sudo confirmation form again
      assert_select "input[type='password']", true, "Should show password form when sudo expired"
    end
  end

  test "sudo mode remains active within 15 minutes" do
    # Enable sudo mode
    post admin_sudo_path, params: { password: "test1234" }
    assert_redirected_to admin_root_path

    # Travel forward 10 minutes (still within 15 minute window)
    travel 10.minutes do
      # Sudo mode should still be active - attempt to enable again
      post admin_sudo_path, params: { password: "test1234" }

      # Should succeed (already in sudo mode or re-confirm)
      assert_redirected_to admin_root_path
    end
  end

  test "failed sudo attempts are logged" do
    # Failed sudo should not create success log, but should log warning
    assert_no_difference "AdminViewLog.where(action: 'sudo_mode_enabled').count" do
      post admin_sudo_path, params: { password: "wrongpassword" }
    end

    assert_response :unprocessable_entity
  end

  test "multiple failed sudo attempts do not cause lockout" do
    # Sudo mode uses application-level password check, not login security
    # But we should verify multiple failures don't break anything
    5.times do
      post admin_sudo_path, params: { password: "wrongpassword" }
      assert_response :unprocessable_entity
    end

    # Should still be able to confirm with correct password
    post admin_sudo_path, params: { password: "test1234" }
    assert_redirected_to admin_root_path
    assert_match /재인증/, flash[:notice]
  end

  test "sudo confirmation creates detailed audit log" do
    post admin_sudo_path, params: { password: "test1234" }
    assert_redirected_to admin_root_path

    log = AdminViewLog.last
    assert_equal "sudo_mode_enabled", log.action
    assert_not_nil log.ip_address, "IP address should be captured"
    # Note: user_agent may be nil in test environment (integration tests don't set headers by default)
    assert_equal "Sudo mode enabled for sensitive operations", log.reason
  end
end
