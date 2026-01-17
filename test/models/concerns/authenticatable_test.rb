# frozen_string_literal: true

require "test_helper"

class AuthenticatableTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  # =========================================
  # remember 메서드 테스트
  # =========================================

  test "remember creates remember_token" do
    assert_nil @user.remember_token

    @user.remember

    assert_not_nil @user.remember_token
    assert_kind_of String, @user.remember_token
  end

  test "remember saves remember_digest to database" do
    assert_nil @user.remember_digest

    @user.remember

    @user.reload
    assert_not_nil @user.remember_digest
  end

  test "remember_digest is a bcrypt hash" do
    @user.remember
    @user.reload

    # BCrypt 해시인지 확인 (BCrypt 해시는 $2로 시작)
    assert @user.remember_digest.start_with?("$2")
  end

  # =========================================
  # forget 메서드 테스트
  # =========================================

  test "forget clears remember_digest" do
    @user.remember
    @user.reload
    assert_not_nil @user.remember_digest

    @user.forget

    @user.reload
    assert_nil @user.remember_digest
  end

  # =========================================
  # authenticated? 메서드 테스트
  # =========================================

  test "authenticated? returns true with valid token" do
    @user.remember

    assert @user.authenticated?(@user.remember_token)
  end

  test "authenticated? returns false with invalid token" do
    @user.remember

    assert_not @user.authenticated?("invalid_token")
  end

  test "authenticated? returns false when remember_digest is nil" do
    @user.update_column(:remember_digest, nil)

    assert_not @user.authenticated?("any_token")
  end

  test "authenticated? handles nil token" do
    @user.remember

    assert_not @user.authenticated?(nil)
  end
end
