# frozen_string_literal: true

require "test_helper"

class ApiTokenableTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:one)
    @user.update!(api_token: nil)  # 테스트 시작 시 토큰 초기화
  end

  # ===== generate_api_token! =====
  test "generate_api_token! creates a 64-character hex token" do
    token = @user.generate_api_token!

    assert_not_nil token
    assert_equal 64, token.length
    assert_match(/\A[a-f0-9]+\z/, token)
  end

  test "generate_api_token! saves the token to database" do
    token = @user.generate_api_token!

    @user.reload
    assert_equal token, @user.api_token
  end

  test "generate_api_token! generates unique tokens" do
    token1 = @user.generate_api_token!
    token2 = @user.generate_api_token!

    assert_not_equal token1, token2
  end

  # ===== revoke_api_token! =====
  test "revoke_api_token! removes the token" do
    @user.generate_api_token!
    assert @user.api_token?

    @user.revoke_api_token!

    @user.reload
    assert_nil @user.api_token
    assert_not @user.api_token?
  end

  # ===== api_token? =====
  test "api_token? returns false when no token exists" do
    assert_not @user.api_token?
  end

  test "api_token? returns true when token exists" do
    @user.generate_api_token!
    assert @user.api_token?
  end
end
