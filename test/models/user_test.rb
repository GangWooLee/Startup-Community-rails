# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  # =========================================
  # Fixtures & Setup
  # =========================================

  def setup
    @user = users(:one)
    @admin = users(:admin)
    @oauth_user = users(:oauth_user)
    @deleted_user = users(:deleted_user)
  end

  # =========================================
  # Validations
  # =========================================

  test "should be valid with valid attributes" do
    user = User.new(
      email: "newuser@test.com",
      password: "test1234",
      name: "New User"
    )
    assert user.valid?
  end

  test "should require email" do
    user = User.new(password: "test1234", name: "Test")
    assert_not user.valid?
    assert_validation_error user, :email
  end

  test "should require unique email" do
    duplicate = User.new(
      email: @user.email,
      password: "test1234",
      name: "Duplicate"
    )
    assert_not duplicate.valid?
    assert_validation_error duplicate, :email
  end

  test "should require valid email format" do
    invalid_emails = ["invalid", "user@", "@domain.com", "user@.com"]
    invalid_emails.each do |email|
      user = User.new(email: email, password: "test1234", name: "Test")
      assert_not user.valid?, "#{email} should be invalid"
    end
  end

  test "should require name" do
    user = User.new(email: "test@test.com", password: "test1234")
    assert_not user.valid?
    assert_validation_error user, :name
  end

  test "should validate name length" do
    user = User.new(email: "test@test.com", password: "test1234", name: "A" * 51)
    assert_not user.valid?
    assert_validation_error user, :name
  end

  test "should require password with minimum 8 characters for local users" do
    user = User.new(email: "test@test.com", password: "short1", name: "Test")
    assert_not user.valid?
    assert_validation_error user, :password, "최소"
  end

  test "should require password with letters and numbers" do
    # 숫자만
    user = User.new(email: "test@test.com", password: "12345678", name: "Test")
    assert_not user.valid?
    assert_validation_error user, :password, "영문과 숫자"

    # 영문만
    user2 = User.new(email: "test2@test.com", password: "abcdefgh", name: "Test")
    assert_not user2.valid?
    assert_validation_error user2, :password, "영문과 숫자"
  end

  test "should reject repeated characters in password" do
    user = User.new(email: "test@test.com", password: "aaaa1234", name: "Test")
    assert_not user.valid?
    assert_validation_error user, :password, "같은 문자를 4개"
  end

  test "should validate bio length" do
    user = @user.dup
    user.email = "newtest@test.com"
    user.bio = "A" * 501
    assert_not user.valid?
    assert_validation_error user, :bio
  end

  test "should validate URL formats" do
    @user.linkedin_url = "not-a-url"
    assert_not @user.valid?

    @user.linkedin_url = "https://linkedin.com/in/user"
    assert @user.valid?
  end

  # =========================================
  # Associations
  # =========================================

  test "should have many posts" do
    assert_respond_to @user, :posts
    assert_kind_of ActiveRecord::Associations::CollectionProxy, @user.posts
  end

  test "should have many comments" do
    assert_respond_to @user, :comments
  end

  test "should have many likes" do
    assert_respond_to @user, :likes
  end

  test "should have many bookmarks" do
    assert_respond_to @user, :bookmarks
  end

  test "should have many oauth_identities" do
    assert_respond_to @user, :oauth_identities
    assert @oauth_user.oauth_identities.any?
  end

  test "should have many notifications" do
    assert_respond_to @user, :notifications
  end

  test "should have many chat_rooms through chat_room_participants" do
    assert_respond_to @user, :chat_rooms
  end

  test "should have many orders" do
    assert_respond_to @user, :orders
  end

  test "should have many user_deletions" do
    assert_respond_to @user, :user_deletions
  end

  # =========================================
  # Scopes
  # =========================================

  test "recent scope should order by created_at desc" do
    users = User.recent
    assert users.first.created_at >= users.last.created_at
  end

  test "active scope should exclude deleted users" do
    active_users = User.active
    assert_not active_users.include?(@deleted_user)
  end

  test "deleted scope should only include deleted users" do
    deleted_users = User.deleted
    assert deleted_users.include?(@deleted_user)
    assert_not deleted_users.include?(@user)
  end

  test "oauth_users scope should only include users with oauth" do
    oauth_users = User.oauth_users
    assert oauth_users.include?(@oauth_user)
  end

  # =========================================
  # Instance Methods
  # =========================================

  test "admin? should return true for admin user" do
    assert @admin.admin?
    assert_not @user.admin?
  end

  test "oauth_user? should return true for user with oauth identities" do
    assert @oauth_user.oauth_user?
  end

  test "local_user? should return true for user without oauth" do
    # one은 oauth_identities가 있으므로 oauth_user
    new_user = User.create!(email: "local@test.com", password: "test1234", name: "Local")
    assert new_user.local_user?
    new_user.destroy
  end

  test "deleted? should return true for deleted user" do
    assert @deleted_user.deleted?
    assert_not @user.deleted?
  end

  test "active? should return true for non-deleted user" do
    assert @user.active?
    assert_not @deleted_user.active?
  end

  # =========================================
  # Remember Me
  # =========================================

  test "remember should generate remember_token and save remember_digest" do
    assert_nil @user.remember_digest
    @user.remember
    assert_not_nil @user.remember_token
    assert_not_nil @user.reload.remember_digest
  end

  test "forget should clear remember_digest" do
    @user.remember
    assert_not_nil @user.remember_digest
    @user.forget
    assert_nil @user.reload.remember_digest
  end

  test "authenticated? should verify remember_token" do
    @user.remember
    token = @user.remember_token
    assert @user.authenticated?(token)
    assert_not @user.authenticated?("wrong_token")
  end

  test "authenticated? should return false if remember_digest is nil" do
    assert_not @user.authenticated?("any_token")
  end

  # =========================================
  # Skills & Profile
  # =========================================

  test "skills_array should return array of skills" do
    @user.skills = "Ruby, Rails, JavaScript"
    assert_equal ["Ruby", "Rails", "JavaScript"], @user.skills_array
  end

  test "skills_array should return empty array for blank skills" do
    @user.skills = nil
    assert_equal [], @user.skills_array
  end

  test "skills_array= should set skills from array" do
    @user.skills_array = ["Python", "Django"]
    assert_equal "Python, Django", @user.skills
  end

  test "availability_badges should return badges array" do
    @user.availability_statuses = ["available_for_work"]
    badges = @user.availability_badges
    assert badges.any? { |b| b[:label] == "외주 가능" }
  end

  test "availability_badges should include custom_status" do
    @user.custom_status = "휴가중"
    badges = @user.availability_badges
    assert badges.any? { |b| b[:label] == "휴가중" }
  end

  # =========================================
  # Notifications & Messages
  # =========================================

  test "unread_notifications_count should return count" do
    assert_respond_to @user, :unread_notifications_count
    assert @user.unread_notifications_count >= 0
  end

  test "has_unread_notifications? should return boolean" do
    assert_respond_to @user, :has_unread_notifications?
  end

  test "total_unread_messages should return count" do
    assert_respond_to @user, :total_unread_messages
    assert @user.total_unread_messages >= 0
  end

  # =========================================
  # Profile Image
  # =========================================

  test "profile_image_url should return avatar_url if no attachment" do
    @oauth_user.avatar_url = "https://example.com/avatar.jpg"
    assert_equal "https://example.com/avatar.jpg", @oauth_user.profile_image_url
  end

  test "has_profile_image? should return true if avatar_url present" do
    @oauth_user.avatar_url = "https://example.com/avatar.jpg"
    assert @oauth_user.has_profile_image?
  end

  test "has_profile_image? should return false if no image" do
    @user.avatar_url = nil
    # Avatar가 attached되어 있지 않은 경우
    assert_not @user.has_profile_image? unless @user.avatar.attached?
  end

  # =========================================
  # Payments
  # =========================================

  test "toss_customer_key should return unique key" do
    key = @user.toss_customer_key
    assert key.start_with?("CUST-")
    assert_equal key, @user.toss_customer_key # 일관성
  end

  # =========================================
  # OAuth
  # =========================================

  test "from_omniauth should create new user with oauth" do
    auth = OmniAuth::AuthHash.new({
      provider: "google",
      uid: "new_google_uid_123",
      info: {
        email: "newgoogle@test.com",
        name: "New Google User",
        image: "https://google.com/avatar.jpg"
      }
    })

    result = nil
    assert_difference "User.count", 1 do
      assert_difference "OauthIdentity.count", 1 do
        result = User.from_omniauth(auth)
      end
    end

    assert_equal false, result[:deleted]
    assert_equal "newgoogle@test.com", result[:user].email
  end

  test "from_omniauth should link to existing user by email" do
    # users(:one)은 이미 Google OAuth가 연결되어 있으므로 GitHub으로 테스트
    auth = OmniAuth::AuthHash.new({
      provider: "github",
      uid: "github_new_uid_for_existing",
      info: {
        email: @user.email,
        name: "Same Email User"
      }
    })

    result = nil
    assert_no_difference "User.count" do
      assert_difference "OauthIdentity.count", 1 do
        result = User.from_omniauth(auth)
      end
    end

    assert_equal @user.id, result[:user].id
  end

  test "from_omniauth should return deleted flag for deleted user" do
    auth = OmniAuth::AuthHash.new({
      provider: "google",
      uid: "deleted_user_uid",
      info: {
        email: @deleted_user.email,
        name: "Deleted User"
      }
    })

    result = User.from_omniauth(auth)
    assert_equal true, result[:deleted]
  end

  test "connected_providers should return array of providers" do
    providers = @oauth_user.connected_providers
    assert_includes providers, "google"
  end

  # =========================================
  # Blacklist Check
  # =========================================

  test "should prevent signup with blacklisted email" do
    # 탈퇴 기록이 있는 이메일로 가입 시도
    # UserDeletion에 email_hash가 저장되어 있어야 함
    email = "blacklisted@test.com"
    email_hash = Digest::SHA256.hexdigest(email.downcase.strip)
    UserDeletion.create!(
      user: @user,
      email_hash: email_hash,
      reason_category: "not_using",
      status: "completed",
      requested_at: Time.current,
      user_snapshot: { email: email, name: "Blacklisted User" }.to_json
    )

    user = User.new(email: email, password: "test1234", name: "Blacklisted")
    assert_not user.valid?
    assert_validation_error user, :email, "탈퇴"
  end

  # =========================================
  # Callbacks
  # =========================================

  test "should downcase email before save" do
    user = User.create!(
      email: "UPPERCASE@TEST.COM",
      password: "test1234",
      name: "Test"
    )
    assert_equal "uppercase@test.com", user.email
    user.destroy
  end

  # =========================================
  # Anonymous Feature - display_name
  # =========================================

  test "display_name returns name when profile not completed" do
    @user.profile_completed = false
    @user.is_anonymous = true
    @user.nickname = "익명닉네임"
    assert_equal @user.name, @user.display_name
  end

  test "display_name returns nickname when anonymous and profile completed" do
    @user.profile_completed = true
    @user.is_anonymous = true
    @user.nickname = "활기찬 개발자"
    assert_equal "활기찬 개발자", @user.display_name
  end

  test "display_name returns name when not anonymous" do
    @user.profile_completed = true
    @user.is_anonymous = false
    @user.nickname = "무시될닉네임"
    assert_equal @user.name, @user.display_name
  end

  # =========================================
  # Anonymous Feature - display_avatar_path
  # =========================================

  test "display_avatar_path returns anonymous avatar when anonymous" do
    @user.profile_completed = true
    @user.is_anonymous = true
    @user.avatar_type = 2
    # avatar_type 2 → anonymous3-.png (0-based to 1-based)
    assert_equal "/anonymous3-.png", @user.display_avatar_path
  end

  test "display_avatar_path returns avatar_url when not anonymous" do
    @user.profile_completed = true
    @user.is_anonymous = false
    @user.avatar_url = "https://example.com/avatar.jpg"
    assert_equal "https://example.com/avatar.jpg", @user.display_avatar_path
  end

  test "display_avatar_path returns nil when no image" do
    @user.profile_completed = true
    @user.is_anonymous = false
    @user.avatar_url = nil
    # avatar가 attached되지 않고 avatar_url도 없으면 nil 반환
    assert_nil @user.display_avatar_path
  end

  # =========================================
  # Anonymous Feature - using_anonymous_avatar?
  # =========================================

  test "using_anonymous_avatar? returns true when profile complete and anonymous" do
    @user.profile_completed = true
    @user.is_anonymous = true
    assert @user.using_anonymous_avatar?
  end

  test "using_anonymous_avatar? returns false when not anonymous" do
    @user.profile_completed = true
    @user.is_anonymous = false
    assert_not @user.using_anonymous_avatar?
  end

  test "using_anonymous_avatar? returns false when profile not completed" do
    @user.profile_completed = false
    @user.is_anonymous = true
    assert_not @user.using_anonymous_avatar?
  end

  # =========================================
  # Anonymous Feature - Nickname Validation
  # =========================================

  test "nickname is required when profile completed" do
    @user.profile_completed = true
    @user.nickname = nil
    assert_not @user.valid?
    assert_validation_error @user, :nickname
  end

  test "nickname is not required when profile not completed" do
    @user.profile_completed = false
    @user.nickname = nil
    assert @user.valid?
  end

  test "nickname must be unique when profile completed" do
    # 먼저 다른 사용자의 닉네임 설정
    other_user = users(:two)
    other_user.update!(profile_completed: true, nickname: "고유닉네임")

    @user.profile_completed = true
    @user.nickname = "고유닉네임"
    assert_not @user.valid?
    assert_validation_error @user, :nickname, "이미 사용 중"
  end

  test "nickname must be 2-20 characters" do
    @user.profile_completed = true

    # 1자 - 실패
    @user.nickname = "A"
    assert_not @user.valid?
    assert_validation_error @user, :nickname

    # 21자 - 실패
    @user.nickname = "A" * 21
    assert_not @user.valid?
    assert_validation_error @user, :nickname

    # 2자 - 성공
    @user.nickname = "AB"
    assert @user.valid?

    # 20자 - 성공
    @user.nickname = "A" * 20
    assert @user.valid?
  end

  test "avatar_type should be within valid range 0-3" do
    @user.profile_completed = true
    @user.nickname = "테스트닉네임"

    (0..3).each do |type|
      @user.avatar_type = type
      assert @user.valid?, "avatar_type #{type} should be valid"
    end
  end

  # =========================================
  # Anonymous Feature - Edge Cases
  # =========================================

  test "display_name handles nil nickname gracefully" do
    @user.profile_completed = true
    @user.is_anonymous = true
    # validation 우회하여 테스트
    @user.instance_variable_set(:@nickname, nil)
    @user.define_singleton_method(:nickname) { nil }

    # name으로 fallback되거나 에러 없이 처리되어야 함
    assert_nothing_raised { @user.display_name }
  end

  test "anonymous settings ignored when profile not completed" do
    @user.profile_completed = false
    @user.is_anonymous = true
    @user.nickname = "무시될닉네임"

    assert_equal @user.name, @user.display_name
    assert_not @user.using_anonymous_avatar?
  end

  test "state transition from real name to anonymous reflects immediately" do
    @user.profile_completed = true
    @user.is_anonymous = false
    assert_equal @user.name, @user.display_name

    @user.is_anonymous = true
    @user.nickname = "새닉네임"
    assert_equal "새닉네임", @user.display_name
  end

  test "state transition from anonymous to real name reflects immediately" do
    @user.profile_completed = true
    @user.is_anonymous = true
    @user.nickname = "익명닉네임"
    assert_equal "익명닉네임", @user.display_name

    @user.is_anonymous = false
    assert_equal @user.name, @user.display_name
  end
end
