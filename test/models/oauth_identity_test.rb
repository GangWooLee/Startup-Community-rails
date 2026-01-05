# frozen_string_literal: true

require "test_helper"

class OauthIdentityTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @oauth_user = users(:oauth_user)
    @google_identity = oauth_identities(:google_one)
    @github_identity = oauth_identities(:github_two)
  end

  # =========================================
  # Association Tests
  # =========================================

  test "should belong to user" do
    assert_respond_to @google_identity, :user
    assert_equal @user, @google_identity.user
  end

  test "user should have many oauth_identities" do
    assert_respond_to @oauth_user, :oauth_identities
    assert_includes @oauth_user.oauth_identities, oauth_identities(:oauth_user_google)
    assert_includes @oauth_user.oauth_identities, oauth_identities(:oauth_user_github)
  end

  # =========================================
  # Validation Tests
  # =========================================

  test "should be valid with valid attributes" do
    identity = OauthIdentity.new(
      user: users(:three),
      provider: "kakao",
      uid: "kakao_123456"
    )
    assert identity.valid?
  end

  test "should require provider" do
    identity = OauthIdentity.new(
      user: @user,
      uid: "some_uid"
    )
    assert_not identity.valid?
    assert_includes identity.errors[:provider], "can't be blank"
  end

  test "should require uid" do
    identity = OauthIdentity.new(
      user: @user,
      provider: "google"
    )
    assert_not identity.valid?
    assert_includes identity.errors[:uid], "can't be blank"
  end

  # =========================================
  # Uniqueness Tests
  # =========================================

  test "should enforce unique provider and uid combination" do
    duplicate = OauthIdentity.new(
      user: users(:three),
      provider: @google_identity.provider,
      uid: @google_identity.uid
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:provider], "has already been taken"
  end

  test "should enforce unique provider per user" do
    # User one already has google OAuth
    another_google = OauthIdentity.new(
      user: @user,
      provider: "google",
      uid: "different_google_uid"
    )
    assert_not another_google.valid?
    assert_includes another_google.errors[:provider], "has already been taken"
  end

  test "same provider can be used by different users with different uid" do
    # User three doesn't have google OAuth yet
    new_google = OauthIdentity.new(
      user: users(:three),
      provider: "google",
      uid: "completely_new_uid_12345"
    )
    assert new_google.valid?
  end

  test "same user can have different providers" do
    # oauth_user has both google and github
    assert_equal 2, @oauth_user.oauth_identities.count
    assert_equal %w[github google], @oauth_user.oauth_identities.pluck(:provider).sort
  end

  # =========================================
  # Edge Cases
  # =========================================

  test "should handle empty string provider" do
    identity = OauthIdentity.new(
      user: @user,
      provider: "",
      uid: "some_uid"
    )
    assert_not identity.valid?
  end

  test "should handle empty string uid" do
    identity = OauthIdentity.new(
      user: @user,
      provider: "google",
      uid: ""
    )
    assert_not identity.valid?
  end
end
