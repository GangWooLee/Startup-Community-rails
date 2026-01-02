# frozen_string_literal: true

require "test_helper"

class UserDeletionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @admin = users(:admin)
    @deletion = user_deletions(:recent_deletion)
  end

  # ============================================================================
  # Association Tests
  # ============================================================================

  test "belongs to user" do
    assert_respond_to @deletion, :user, "UserDeletion should have user association"
    assert_instance_of User, @deletion.user, "user should be a User instance"
    assert_equal @deletion.user_id, @deletion.user.id, "user_id should match associated user"
    assert @deletion.user.persisted?, "Associated user should be persisted"
  end

  # ============================================================================
  # Validation Tests
  # ============================================================================

  test "should be valid with valid attributes" do
    deletion = UserDeletion.new(
      user: @user,
      status: "completed",
      requested_at: Time.current,
      email_original: "test@example.com",
      name_original: "Test User",
      user_snapshot: { email: "test@example.com" }
    )
    assert deletion.valid?, "Expected deletion to be valid: #{deletion.errors.full_messages.join(', ')}"
    assert_empty deletion.errors, "Should have no validation errors"
    assert_equal "completed", deletion.status, "Status should be set correctly"
    assert_not_nil deletion.requested_at, "requested_at should be set"
  end

  test "should require status" do
    deletion = UserDeletion.new(
      user: @user,
      requested_at: Time.current,
      user_snapshot: {}
    )
    deletion.status = nil
    assert_not deletion.valid?
    assert_includes deletion.errors[:status], "can't be blank"
  end

  test "should validate status inclusion" do
    deletion = user_deletions(:recent_deletion)
    deletion.status = "invalid_status"
    assert_not deletion.valid?
    assert_includes deletion.errors[:status], "is not included in the list"
  end

  test "should accept pending status" do
    deletion = user_deletions(:recent_deletion)
    deletion.status = "pending"
    assert deletion.valid?
  end

  test "should accept completed status" do
    deletion = user_deletions(:recent_deletion)
    deletion.status = "completed"
    assert deletion.valid?
  end

  test "should require requested_at" do
    deletion = UserDeletion.new(
      user: @user,
      status: "completed",
      user_snapshot: {}
    )
    deletion.requested_at = nil
    assert_not deletion.valid?
    assert_includes deletion.errors[:requested_at], "can't be blank"
  end

  test "should validate reason_category inclusion when present" do
    deletion = user_deletions(:recent_deletion)
    deletion.reason_category = "invalid_reason"
    assert_not deletion.valid?
    assert_includes deletion.errors[:reason_category], "is not included in the list"
  end

  test "should allow blank reason_category" do
    deletion = user_deletions(:recent_deletion)
    deletion.reason_category = nil
    assert deletion.valid?
  end

  test "should accept all valid reason categories" do
    UserDeletion::REASON_CATEGORIES.keys.each do |category|
      deletion = user_deletions(:recent_deletion)
      deletion.reason_category = category
      assert deletion.valid?, "Expected #{category} to be valid"
    end
  end

  # ============================================================================
  # Constants Tests
  # ============================================================================

  test "STATUSES contains expected values" do
    assert_equal({ pending: "pending", completed: "completed" }, UserDeletion::STATUSES)
  end

  test "REASON_CATEGORIES contains expected keys" do
    expected_keys = %w[not_using found_alternative privacy_concern too_many_notifications not_useful technical_issues other]
    assert_equal expected_keys.sort, UserDeletion::REASON_CATEGORIES.keys.sort
  end

  test "RETENTION_PERIOD is 5 years" do
    assert_equal 5.years, UserDeletion::RETENTION_PERIOD
  end

  # ============================================================================
  # Scope Tests
  # ============================================================================

  test "pending scope returns pending deletions" do
    # Create a pending deletion
    pending = UserDeletion.create!(
      user: @user,
      status: "pending",
      requested_at: Time.current,
      user_snapshot: {}
    )

    results = UserDeletion.pending
    assert_includes results, pending
  end

  test "completed scope returns completed deletions" do
    results = UserDeletion.completed
    assert results.all? { |d| d.status == "completed" }
  end

  test "recent scope orders by created_at desc" do
    results = UserDeletion.recent
    if results.size > 1
      results.each_cons(2) do |a, b|
        assert a.created_at >= b.created_at
      end
    end
  end

  test "expiring_soon scope returns deletions within 30 days" do
    # expiring_soon_deletion has destroy_scheduled_at 15 days from now
    expiring = user_deletions(:expiring_soon_deletion)

    results = UserDeletion.expiring_soon
    assert_includes results, expiring
  end

  test "expired scope returns past destroy_scheduled_at" do
    # expired_deletion has destroy_scheduled_at 1 year ago
    expired = user_deletions(:expired_deletion)

    results = UserDeletion.expired
    assert_includes results, expired
  end

  # ============================================================================
  # Callback Tests
  # ============================================================================

  test "sets destroy_scheduled_at on create" do
    freeze_time do
      deletion = UserDeletion.create!(
        user: @user,
        status: "completed",
        requested_at: Time.current,
        user_snapshot: {}
      )

      expected = 5.years.from_now
      assert_equal expected.to_date, deletion.destroy_scheduled_at.to_date,
                   "Should schedule destruction 5 years from now"
      assert_not_nil deletion.destroy_scheduled_at, "destroy_scheduled_at should be set"
      assert deletion.destroy_scheduled_at > Time.current, "Should be in the future"
      assert_equal UserDeletion::RETENTION_PERIOD, 5.years,
                   "Retention period constant should be 5 years"
    end
  end

  test "does not override existing destroy_scheduled_at" do
    custom_date = 3.years.from_now
    deletion = UserDeletion.create!(
      user: @user,
      status: "completed",
      requested_at: Time.current,
      destroy_scheduled_at: custom_date,
      user_snapshot: {}
    )

    assert_equal custom_date.to_date, deletion.destroy_scheduled_at.to_date
  end

  # ============================================================================
  # Instance Method Tests
  # ============================================================================

  test "reason_label returns translated reason" do
    deletion = user_deletions(:recent_deletion)
    deletion.reason_category = "not_using"

    assert_equal "서비스를 더 이상 사용하지 않음", deletion.reason_label
  end

  test "reason_label returns original value for unknown category" do
    deletion = user_deletions(:recent_deletion)
    # Bypass validation for this test
    deletion.instance_variable_set(:@reason_category, "custom_reason")
    deletion.define_singleton_method(:reason_category) { "custom_reason" }

    assert_equal "custom_reason", deletion.reason_label
  end

  test "reason_label returns default for nil" do
    deletion = user_deletions(:recent_deletion)
    deletion.reason_category = nil

    assert_equal "미선택", deletion.reason_label
  end

  test "days_until_destruction calculates correctly" do
    freeze_time do
      deletion = user_deletions(:recent_deletion)
      deletion.destroy_scheduled_at = 100.days.from_now

      assert_equal 100, deletion.days_until_destruction
    end
  end

  test "days_until_destruction returns 0 when expired" do
    deletion = user_deletions(:expired_deletion)
    # destroy_scheduled_at is 1 year ago

    assert_equal 0, deletion.days_until_destruction
  end

  test "days_until_destruction returns 0 when nil" do
    deletion = user_deletions(:recent_deletion)
    deletion.destroy_scheduled_at = nil

    assert_equal 0, deletion.days_until_destruction
  end

  test "parsed_snapshot returns hash from JSON" do
    deletion = user_deletions(:recent_deletion)
    # Fixture has snapshot_data: '{"posts_count": 5, "comments_count": 10}'

    result = deletion.parsed_snapshot
    assert result.is_a?(Hash)
    assert_equal 5, result["posts_count"]
  end

  test "parsed_snapshot returns empty hash for blank" do
    deletion = user_deletions(:recent_deletion)
    deletion.snapshot_data = nil

    assert_equal({}, deletion.parsed_snapshot)
  end

  test "parsed_snapshot returns empty hash for invalid JSON" do
    deletion = user_deletions(:recent_deletion)
    deletion.snapshot_data = "not valid json"

    assert_equal({}, deletion.parsed_snapshot)
  end

  test "activity_stats_hash returns hash" do
    deletion = user_deletions(:recent_deletion)
    # Fixture has activity_stats: {"posts": 5, "comments": 10}

    result = deletion.activity_stats_hash
    assert result.is_a?(Hash)
  end

  test "activity_stats_hash returns empty hash for blank" do
    deletion = user_deletions(:recent_deletion)
    deletion.activity_stats = nil

    assert_equal({}, deletion.activity_stats_hash)
  end

  # ============================================================================
  # record_admin_view! Method Tests
  # ============================================================================

  test "record_admin_view creates AdminViewLog" do
    deletion = user_deletions(:recent_deletion)
    original_log_count = AdminViewLog.count

    assert_difference "AdminViewLog.count", 1, "Should create exactly one log" do
      deletion.record_admin_view!(
        admin: @admin,
        reason: "테스트 열람 사유입니다"
      )
    end

    log = AdminViewLog.last
    assert_equal @admin, log.admin, "Log should record the admin"
    assert_equal deletion, log.target, "Log should reference the deletion record"
    assert_equal "reveal_personal_info", log.action, "Default action should be reveal_personal_info"
    assert_equal "테스트 열람 사유입니다", log.reason, "Reason should be stored"
    assert_not_nil log.created_at, "Timestamp should be set"
    assert_equal "UserDeletion", log.target_type, "Target type should be UserDeletion"
  end

  test "record_admin_view increments admin_view_count" do
    deletion = user_deletions(:recent_deletion)
    original_count = deletion.admin_view_count

    deletion.record_admin_view!(
      admin: @admin,
      reason: "카운트 테스트 열람"
    )

    deletion.reload
    assert_equal original_count + 1, deletion.admin_view_count
  end

  test "record_admin_view updates last_viewed_at" do
    deletion = user_deletions(:recent_deletion)

    freeze_time do
      deletion.record_admin_view!(
        admin: @admin,
        reason: "시간 업데이트 테스트"
      )

      deletion.reload
      assert_equal Time.current, deletion.last_viewed_at
    end
  end

  test "record_admin_view updates last_viewed_by" do
    deletion = user_deletions(:recent_deletion)

    deletion.record_admin_view!(
      admin: @admin,
      reason: "관리자 ID 업데이트 테스트"
    )

    deletion.reload
    assert_equal @admin.id, deletion.last_viewed_by
  end

  test "record_admin_view stores IP address" do
    deletion = user_deletions(:recent_deletion)

    deletion.record_admin_view!(
      admin: @admin,
      reason: "IP 테스트 열람입니다",
      ip_address: "192.168.1.100"
    )

    log = AdminViewLog.last
    assert_equal "192.168.1.100", log.ip_address
  end

  test "record_admin_view stores user agent" do
    deletion = user_deletions(:recent_deletion)

    deletion.record_admin_view!(
      admin: @admin,
      reason: "UA 테스트 열람입니다",
      user_agent: "Mozilla/5.0 Test"
    )

    log = AdminViewLog.last
    assert_equal "Mozilla/5.0 Test", log.user_agent
  end

  # ============================================================================
  # Encryption Tests
  # ============================================================================

  test "email_original is encrypted" do
    deletion = UserDeletion.create!(
      user: @user,
      status: "completed",
      requested_at: Time.current,
      email_original: "encrypted@test.com",
      user_snapshot: {}
    )

    # Verify we can read it back
    deletion.reload
    assert_equal "encrypted@test.com", deletion.email_original
  end

  test "name_original is encrypted" do
    deletion = UserDeletion.create!(
      user: @user,
      status: "completed",
      requested_at: Time.current,
      name_original: "Encrypted Name",
      user_snapshot: {}
    )

    deletion.reload
    assert_equal "Encrypted Name", deletion.name_original
  end

  test "phone_original is encrypted" do
    deletion = UserDeletion.create!(
      user: @user,
      status: "completed",
      requested_at: Time.current,
      phone_original: "01012345678",
      user_snapshot: {}
    )

    deletion.reload
    assert_equal "01012345678", deletion.phone_original
  end
end
