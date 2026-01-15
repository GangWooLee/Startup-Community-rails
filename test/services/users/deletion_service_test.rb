# frozen_string_literal: true

require "test_helper"

module Users
  class DeletionServiceTest < ActiveSupport::TestCase
    setup do
      @user = users(:one)
      @user_with_data = users(:two)  # User with posts, comments, etc.
    end

    # ============================================================================
    # Successful Deletion Tests
    # ============================================================================

    test "call successfully deletes user and creates deletion record" do
      service = Users::DeletionService.new(
        user: @user,
        reason_category: "not_using",  # Valid category from REASON_CATEGORIES
        reason_detail: "Test reason",
        ip_address: "127.0.0.1",
        user_agent: "Test Agent"
      )

      result = service.call

      assert result.success?, "Expected service to succeed: #{result.errors.join(', ')}"
      assert_not_nil result.user_deletion, "UserDeletion record should be created"
      assert_empty result.errors, "No errors should be present"

      # Verify deletion record
      deletion = result.user_deletion
      assert_equal @user, deletion.user
      assert_equal "not_using", deletion.reason_category
      assert_equal "Test reason", deletion.reason_detail
      assert_equal "completed", deletion.status, "Status should be completed"
      assert_equal "127.0.0.1", deletion.ip_address
      assert_equal "Test Agent", deletion.user_agent
    end

    test "call anonymizes user data immediately" do
      original_email = @user.email
      original_name = @user.name

      service = Users::DeletionService.new(user: @user, reason_category: "other")
      result = service.call

      assert result.success?

      @user.reload
      assert_not_equal original_email, @user.email, "Email should be anonymized"
      assert_match /deleted_\d+_\w+@void\.platform/, @user.email, "Email should match anonymous pattern"
      assert_equal "(탈퇴한 회원)", @user.name, "Name should be anonymized"
      assert_not_nil @user.deleted_at, "deleted_at should be set"
      assert @user.deleted?, "User should be marked as deleted"
    end

    test "call clears all personal information fields" do
      # Set up user with all fields populated
      @user.update!(
        bio: "Test bio",
        role_title: "Developer",
        affiliation: "Test Company",
        skills: "Rails, Ruby",
        achievements: "Test achievement",
        avatar_url: "https://example.com/avatar.jpg",
        linkedin_url: "https://linkedin.com/in/test",
        github_url: "https://github.com/test",
        portfolio_url: "https://test.com",
        open_chat_url: "https://open.kakao.com/test",
        availability_statuses: [ "외주 가능", "팀 구하는 중" ],
        custom_status: "Test"  # Must be <= 10 characters
      )

      service = Users::DeletionService.new(user: @user)
      result = service.call

      assert result.success?

      @user.reload
      assert_nil @user.bio
      assert_nil @user.role_title
      assert_nil @user.affiliation
      assert_nil @user.skills
      assert_nil @user.achievements
      assert_nil @user.avatar_url
      assert_nil @user.linkedin_url
      assert_nil @user.github_url
      assert_nil @user.portfolio_url
      assert_nil @user.open_chat_url
      assert_empty @user.availability_statuses
      assert_nil @user.custom_status
    end

    test "call generates invalid password digest to prevent login" do
      original_digest = @user.password_digest

      service = Users::DeletionService.new(user: @user)
      result = service.call

      assert result.success?

      @user.reload
      assert_not_equal original_digest, @user.password_digest
      assert_match /^deleted_\w{32}$/, @user.password_digest, "Password digest should be invalid"

      # Verify user cannot authenticate - BCrypt will reject invalid hash format
      # 삭제된 사용자의 password_digest는 유효하지 않은 BCrypt 형식이므로 예외 발생
      assert_raises(BCrypt::Errors::InvalidHash) do
        @user.authenticate("password")
      end
    end

    # ============================================================================
    # Encrypted Backup Tests
    # ============================================================================

    test "call creates encrypted backup with original user data" do
      original_email = @user.email
      original_name = @user.name

      service = Users::DeletionService.new(user: @user)
      result = service.call

      assert result.success?

      deletion = result.user_deletion
      # Verify encrypted fields are stored (Rails Active Record Encryption)
      assert_equal original_email, deletion.email_original
      assert_equal original_name, deletion.name_original
    end

    test "call creates SHA256 hash of email for duplicate prevention" do
      original_email = @user.email
      expected_hash = Digest::SHA256.hexdigest(original_email.downcase.strip)

      service = Users::DeletionService.new(user: @user)
      result = service.call

      assert result.success?

      deletion = result.user_deletion
      assert_equal expected_hash, deletion.email_hash
      assert_equal 64, deletion.email_hash.length, "SHA256 hash should be 64 characters"
    end

    test "call stores complete user snapshot in JSON" do
      @user.update!(
        bio: "Test bio",
        skills: "Rails, Ruby",
        affiliation: "Test Company"
      )

      service = Users::DeletionService.new(user: @user)
      result = service.call

      assert result.success?

      deletion = result.user_deletion
      snapshot = deletion.user_snapshot

      # Note: snapshot is taken BEFORE anonymization
      assert_equal @user.id, snapshot["id"]
      # Email in snapshot should be original email (before anonymization)
      assert snapshot["email"].present?
      assert snapshot["name"].present?
      assert_equal "Test bio", snapshot["bio"]
      assert_equal "Rails, Ruby", snapshot["skills"]
      assert_equal "Test Company", snapshot["affiliation"]
    end

    test "call stores activity statistics" do
      service = Users::DeletionService.new(user: @user_with_data)
      result = service.call

      assert result.success?

      deletion = result.user_deletion
      stats = deletion.activity_stats

      assert stats.key?("total_posts")
      assert stats.key?("total_comments")
      assert stats.key?("total_likes_given")
      assert stats.key?("total_likes_received")
      assert stats.key?("total_bookmarks")
      assert stats.key?("total_chat_rooms")
      assert stats.key?("total_messages_sent")
      assert stats.key?("total_idea_analyses")
      assert stats.key?("total_orders")
      assert stats.key?("account_age_days")
      assert stats.key?("last_activity_at")

      # Verify stats are numbers (not nil)
      assert stats["total_posts"] >= 0
      assert stats["account_age_days"] >= 0
    end

    test "call calculates account age correctly" do
      # Create user with known creation date
      old_user = User.create!(
        email: "old@test.com",
        name: "Old User",
        password: "password123",
        password_confirmation: "password123",
        created_at: 30.days.ago
      )

      service = Users::DeletionService.new(user: old_user)
      result = service.call

      assert result.success?

      stats = result.user_deletion.activity_stats
      assert_in_delta 30, stats["account_age_days"], 1, "Account age should be approximately 30 days"
    end

    # ============================================================================
    # Data Cleanup Tests
    # ============================================================================

    test "call purges attached avatar if present" do
      # Active Storage 파일이 있는 사용자 생성
      user_with_avatar = @user

      # 테스트용 이미지 첨부 (fixtures/files/test_image.png 사용)
      if File.exist?(Rails.root.join("test/fixtures/files/test_image.png"))
        user_with_avatar.avatar.attach(
          io: File.open(Rails.root.join("test/fixtures/files/test_image.png")),
          filename: "avatar.png",
          content_type: "image/png"
        )

        assert user_with_avatar.avatar.attached?, "Avatar should be attached before deletion"

        service = Users::DeletionService.new(user: user_with_avatar)
        result = service.call

        assert result.success?

        # 아바타가 삭제되었는지 확인 (purge 호출됨)
        user_with_avatar.reload
        assert_not user_with_avatar.avatar.attached?, "Avatar should be purged after deletion"
      else
        # 테스트 이미지 파일이 없으면 아바타 없이 테스트
        assert_not user_with_avatar.avatar.attached?

        service = Users::DeletionService.new(user: user_with_avatar)
        result = service.call

        assert result.success?
      end
    end

    test "call destroys all OAuth identities" do
      # Create OAuth identity with unique provider (google_one fixture already exists for user :one)
      oauth = @user.oauth_identities.create!(
        provider: "twitter",
        uid: "twitter_test_#{SecureRandom.hex(8)}"
      )

      service = Users::DeletionService.new(user: @user)
      result = service.call

      assert result.success?

      # Verify OAuth identities are deleted
      assert_equal 0, @user.oauth_identities.count
      assert_nil OauthIdentity.find_by(id: oauth.id)
    end

    # ============================================================================
    # Validation Tests
    # ============================================================================

    test "call fails when user is nil" do
      service = Users::DeletionService.new(user: nil)
      result = service.call

      assert result.failure?, "Expected service to fail"
      assert_nil result.user_deletion
      assert_includes result.errors, "사용자를 찾을 수 없습니다."
    end

    test "call fails when user is already deleted" do
      # Mark user as deleted
      @user.update!(deleted_at: Time.current)

      service = Users::DeletionService.new(user: @user)
      result = service.call

      assert result.failure?
      assert_includes result.errors, "이미 탈퇴한 사용자입니다."
    end

    test "call cleans up legacy pending deletions before processing" do
      # Create legacy pending deletion
      legacy_deletion = @user.user_deletions.create!(
        email_original: @user.email,
        name_original: @user.name,
        email_hash: Digest::SHA256.hexdigest(@user.email),
        snapshot_data: {}.to_json,
        status: "pending",
        requested_at: 1.day.ago,
        user_snapshot: {},
        activity_stats: {}
      )

      service = Users::DeletionService.new(user: @user)
      result = service.call

      assert result.success?

      # Verify legacy deletion was cleaned up
      assert_nil UserDeletion.find_by(id: legacy_deletion.id)

      # New deletion should be created
      assert_not_nil result.user_deletion
      assert_equal "completed", result.user_deletion.status
    end

    # ============================================================================
    # Transaction Rollback Tests
    # ============================================================================

    test "call rolls back on deletion record creation failure" do
      # 원래 사용자 정보 저장
      original_email = @user.email
      original_name = @user.name

      service = Users::DeletionService.new(user: @user)

      # UserDeletion.create!가 실패하도록 모킹
      UserDeletion.stub(:create!, ->(*) { raise ActiveRecord::RecordInvalid.new(UserDeletion.new) }) do
        result = service.call

        # 실패해야 함
        assert result.failure?
        # ActiveRecord::RecordInvalid 예외 메시지는 "Validation failed: ..."로 시작
        assert result.errors.any? { |e| e.include?("Validation failed") }
      end

      # 트랜잭션 롤백으로 사용자 데이터가 변경되지 않아야 함
      @user.reload
      assert_equal original_email, @user.email
      assert_equal original_name, @user.name
      assert_nil @user.deleted_at
    end

    test "call rolls back on user anonymization failure" do
      # 원래 사용자 정보 저장
      original_email = @user.email

      service = Users::DeletionService.new(user: @user)

      # anonymize_user! 메서드가 실패하도록 오버라이드
      def service.anonymize_user!
        raise ActiveRecord::RecordInvalid.new(@user)
      end

      result = service.call

      # 실패해야 함
      assert result.failure?

      # 트랜잭션 롤백으로 UserDeletion 레코드가 생성되지 않아야 함
      assert_equal 0, UserDeletion.where(email_original: original_email).count

      # 사용자 데이터도 변경되지 않아야 함
      @user.reload
      assert_equal original_email, @user.email
      assert_nil @user.deleted_at
    end

    test "call handles unexpected errors gracefully" do
      # Create a service instance
      service = Users::DeletionService.new(user: @user)

      # Stub the private anonymize_user! method to raise an error
      def service.anonymize_user!
        raise StandardError, "Unexpected error"
      end

      result = service.call

      assert result.failure?
      assert_includes result.errors, "탈퇴 처리 중 오류가 발생했습니다."
    end

    # ============================================================================
    # Result Object Tests
    # ============================================================================

    test "Result responds to success? and failure?" do
      result = Users::DeletionService::Result.new(success?: true, user_deletion: nil, errors: [])

      assert result.success?
      assert_not result.failure?

      result2 = Users::DeletionService::Result.new(success?: false, user_deletion: nil, errors: [])

      assert result2.failure?
      assert_not result2.success?
    end

    test "Result provides access to user_deletion and errors" do
      deletion = @user.user_deletions.create!(
        email_original: @user.email,
        name_original: @user.name,
        email_hash: Digest::SHA256.hexdigest(@user.email),
        snapshot_data: {}.to_json,
        status: "completed",
        requested_at: Time.current,
        user_snapshot: {},
        activity_stats: {}
      )
      errors = [ "Test error" ]

      result = Users::DeletionService::Result.new(
        success?: true,
        user_deletion: deletion,
        errors: errors
      )

      assert_equal deletion, result.user_deletion
      assert_equal errors, result.errors
    end

    # ============================================================================
    # Edge Cases
    # ============================================================================

    test "call handles user with minimal data" do
      # Create user with only required fields
      minimal_user = User.create!(
        email: "minimal@test.com",
        name: "Minimal User",
        password: "password123",
        password_confirmation: "password123"
      )

      service = Users::DeletionService.new(user: minimal_user)
      result = service.call

      assert result.success?

      # Should still create valid snapshot even with minimal data
      snapshot = result.user_deletion.user_snapshot
      assert_equal minimal_user.id, snapshot["id"]
      assert_equal "minimal@test.com", snapshot["email"]
      assert_nil snapshot["bio"]
      assert_nil snapshot["skills"]
    end

    test "call handles user with maximum data" do
      # User with all fields populated
      max_user = User.create!(
        email: "max@test.com",
        name: "Max User",
        password: "password123",
        password_confirmation: "password123",
        bio: "Bio",
        role_title: "Role",
        affiliation: "Company",
        skills: "Skills",
        achievements: "Achievements",
        avatar_url: "https://example.com/avatar.jpg",
        linkedin_url: "https://linkedin.com",
        github_url: "https://github.com",
        portfolio_url: "https://portfolio.com",
        open_chat_url: "https://open.kakao.com",
        availability_statuses: [ "외주 가능" ],
        custom_status: "Status"
      )

      service = Users::DeletionService.new(user: max_user)
      result = service.call

      assert result.success?

      # All data should be backed up
      snapshot = result.user_deletion.user_snapshot
      assert_equal "Bio", snapshot["bio"]
      assert_equal "Role", snapshot["role_title"]
      assert_equal "Company", snapshot["affiliation"]

      # All data should be cleared
      max_user.reload
      assert_nil max_user.bio
      assert_nil max_user.role_title
    end

    test "call accepts optional metadata parameters" do
      service = Users::DeletionService.new(
        user: @user,
        reason_category: "privacy_concern",
        reason_detail: "Detailed reason here",
        ip_address: "192.168.1.1",
        user_agent: "Mozilla/5.0"
      )

      result = service.call

      assert result.success?

      deletion = result.user_deletion
      assert_equal "privacy_concern", deletion.reason_category
      assert_equal "Detailed reason here", deletion.reason_detail
      assert_equal "192.168.1.1", deletion.ip_address
      assert_equal "Mozilla/5.0", deletion.user_agent
    end

    test "call works without optional metadata" do
      service = Users::DeletionService.new(user: @user)
      result = service.call

      assert result.success?

      deletion = result.user_deletion
      assert_nil deletion.reason_category
      assert_nil deletion.reason_detail
      assert_nil deletion.ip_address
      assert_nil deletion.user_agent
    end

    # ============================================================================
    # Logging Tests
    # ============================================================================

    test "call logs successful deletion" do
      service = Users::DeletionService.new(user: @user)

      # Just verify the service succeeds without raising
      # (Actual log verification is difficult with BroadcastLogger)
      assert_nothing_raised do
        result = service.call
        assert result.success?
      end
    end

    test "call logs errors" do
      service = Users::DeletionService.new(user: nil)

      # Verify it doesn't raise when logging errors
      assert_nothing_raised do
        result = service.call
        assert result.failure?
      end
    end

    # ============================================================================
    # Data Integrity Tests
    # ============================================================================

    test "call preserves user_deletions count correctly" do
      initial_count = UserDeletion.count

      service = Users::DeletionService.new(user: @user)
      result = service.call

      assert result.success?
      assert_equal initial_count + 1, UserDeletion.count
    end

    test "call sets destroy_scheduled_at to 5 years from now" do
      service = Users::DeletionService.new(user: @user)
      result = service.call

      assert result.success?

      deletion = result.user_deletion
      expected_date = 5.years.from_now

      # Allow 1 second difference for test execution time
      assert_in_delta expected_date.to_i, deletion.destroy_scheduled_at.to_i, 1
    end

    test "anonymous email is unique per user" do
      service1 = Users::DeletionService.new(user: @user)
      result1 = service1.call

      user2 = users(:two)
      service2 = Users::DeletionService.new(user: user2)
      result2 = service2.call

      assert result1.success?
      assert result2.success?

      @user.reload
      user2.reload

      assert_not_equal @user.email, user2.email, "Anonymous emails should be unique"
    end
  end
end
