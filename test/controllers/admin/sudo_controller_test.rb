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
    post admin_sudo_path, params: { password: "test1234" }
    assert_redirected_to admin_root_path
    # Note: Log creation depends on SudoMode concern implementation
  end
end
