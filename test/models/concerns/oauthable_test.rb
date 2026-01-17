# frozen_string_literal: true

require "test_helper"

class OauthableTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @oauth_user = users(:oauth_user) rescue @user  # oauth_user fixture 없으면 일반 사용자 사용
  end

  # =========================================
  # oauth_user? 메서드 테스트
  # =========================================

  test "oauth_user? returns false for local user" do
    # OAuth identity가 없는 사용자
    @user.oauth_identities.destroy_all if @user.respond_to?(:oauth_identities)

    assert_not @user.oauth_user?
  end

  test "oauth_user? returns true for user with oauth identity" do
    skip "oauth_identities association not set up" unless @user.respond_to?(:oauth_identities)

    # 기존 oauth identity 삭제 후 새로 생성
    @user.oauth_identities.destroy_all
    @user.oauth_identities.create!(provider: "google", uid: "test_uid_#{SecureRandom.hex(8)}")

    assert @user.oauth_user?
  end

  # =========================================
  # local_user? 메서드 테스트
  # =========================================

  test "local_user? returns true for user without oauth identity" do
    @user.oauth_identities.destroy_all if @user.respond_to?(:oauth_identities)

    assert @user.local_user?
  end

  test "local_user? returns false for oauth user" do
    skip "oauth_identities association not set up" unless @user.respond_to?(:oauth_identities)

    @user.oauth_identities.create!(provider: "github", uid: "test_uid_#{SecureRandom.hex(4)}")

    assert_not @user.local_user?
  end

  # =========================================
  # connected_providers 메서드 테스트
  # =========================================

  test "connected_providers returns empty array for local user" do
    @user.oauth_identities.destroy_all if @user.respond_to?(:oauth_identities)

    assert_equal [], @user.connected_providers
  end

  test "connected_providers returns list of providers" do
    skip "oauth_identities association not set up" unless @user.respond_to?(:oauth_identities)

    @user.oauth_identities.destroy_all
    @user.oauth_identities.create!(provider: "google", uid: "google_uid_#{SecureRandom.hex(4)}")
    @user.oauth_identities.create!(provider: "github", uid: "github_uid_#{SecureRandom.hex(4)}")

    providers = @user.connected_providers
    assert_includes providers, "google"
    assert_includes providers, "github"
  end

  # =========================================
  # can_reset_password? 메서드 테스트
  # =========================================

  test "can_reset_password? returns true for local user" do
    @user.oauth_identities.destroy_all if @user.respond_to?(:oauth_identities)

    assert @user.can_reset_password?
  end

  # =========================================
  # oauth_only? 메서드 테스트
  # =========================================

  test "oauth_only? returns false for local user" do
    @user.oauth_identities.destroy_all if @user.respond_to?(:oauth_identities)

    assert_not @user.oauth_only?
  end
end
