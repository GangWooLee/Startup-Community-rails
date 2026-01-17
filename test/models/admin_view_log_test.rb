# frozen_string_literal: true

require "test_helper"

class AdminViewLogTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin)
    @deletion = user_deletions(:recent_deletion)
  end

  # ============================================================================
  # Association Tests
  # ============================================================================

  test "belongs to admin" do
    log = AdminViewLog.new(
      admin: @admin,
      target: @deletion,
      action: "reveal_personal_info",
      reason: "테스트 열람 사유입니다"
    )
    assert_respond_to log, :admin, "Should have admin association"
    assert_equal @admin, log.admin, "Admin should match"
    assert_equal @admin.id, log.admin_id, "admin_id should be set"
    assert @admin.is_admin?, "Associated user should be admin"
  end

  test "belongs to target (polymorphic)" do
    log = AdminViewLog.new(
      admin: @admin,
      target: @deletion,
      action: "reveal_personal_info",
      reason: "테스트 열람 사유입니다"
    )
    assert_respond_to log, :target, "Should have polymorphic target association"
    assert_equal @deletion, log.target, "Target should match deletion"
    assert_equal "UserDeletion", log.target_type, "target_type should be stored"
    assert_equal @deletion.id, log.target_id, "target_id should match"
    assert log.target.is_a?(UserDeletion), "Target should be a UserDeletion instance"
  end

  # ============================================================================
  # Validation Tests
  # ============================================================================

  test "should be valid with valid attributes" do
    log = AdminViewLog.new(
      admin: @admin,
      target: @deletion,
      action: "reveal_personal_info",
      reason: "테스트 열람 사유입니다"
    )
    assert log.valid?, "Expected log to be valid: #{log.errors.full_messages.join(', ')}"
  end

  test "should require action" do
    log = AdminViewLog.new(
      admin: @admin,
      target: @deletion,
      action: nil,
      reason: "테스트 열람 사유입니다"
    )
    assert_not log.valid?
    assert_includes log.errors[:action], "can't be blank"
  end

  test "should require reason" do
    log = AdminViewLog.new(
      admin: @admin,
      target: @deletion,
      action: "reveal_personal_info",
      reason: nil
    )
    assert_not log.valid?
    assert_includes log.errors[:reason], "can't be blank"
  end

  test "should require reason minimum length" do
    log = AdminViewLog.new(
      admin: @admin,
      target: @deletion,
      action: "reveal_personal_info",
      reason: "짧음"  # 2 chars, minimum is 5
    )
    assert_not log.valid?
    # Custom error message: "는 최소 5자 이상 입력해주세요"
    assert log.errors[:reason].any? { |msg| msg.include?("5") }
  end

  test "should accept exactly 5 character reason" do
    log = AdminViewLog.new(
      admin: @admin,
      target: @deletion,
      action: "reveal_personal_info",
      reason: "12345"
    )
    assert log.valid?
  end

  test "should require admin" do
    log = AdminViewLog.new(
      target: @deletion,
      action: "reveal_personal_info",
      reason: "테스트 열람 사유입니다"
    )
    assert_not log.valid?
    assert_includes log.errors[:admin], "must exist"
  end

  test "should require target" do
    log = AdminViewLog.new(
      admin: @admin,
      action: "reveal_personal_info",
      reason: "테스트 열람 사유입니다"
    )
    assert_not log.valid?
    assert_includes log.errors[:target], "must exist"
  end

  # ============================================================================
  # Scope Tests
  # ============================================================================

  test "recent scope orders by created_at desc" do
    # Create multiple logs
    log1 = AdminViewLog.create!(
      admin: @admin,
      target: @deletion,
      action: "reveal_personal_info",
      reason: "첫 번째 열람입니다"
    )
    log2 = AdminViewLog.create!(
      admin: @admin,
      target: @deletion,
      action: "reveal_personal_info",
      reason: "두 번째 열람입니다"
    )

    results = AdminViewLog.recent
    # log2 should be first (more recent)
    assert_equal log2, results.first
  end

  test "by_admin scope filters by admin id" do
    log = AdminViewLog.create!(
      admin: @admin,
      target: @deletion,
      action: "reveal_personal_info",
      reason: "관리자 필터 테스트"
    )

    results = AdminViewLog.by_admin(@admin.id)
    assert_includes results, log
    assert results.all? { |l| l.admin_id == @admin.id }
  end

  test "for_target scope filters by target" do
    log = AdminViewLog.create!(
      admin: @admin,
      target: @deletion,
      action: "reveal_personal_info",
      reason: "타겟 필터 테스트입니다"
    )

    results = AdminViewLog.for_target(@deletion)
    assert_includes results, log
    assert results.all? { |l| l.target == @deletion }
  end

  # ============================================================================
  # Constants Tests
  # ============================================================================

  test "ACTIONS includes all action categories" do
    # Check that all categories are included
    assert AdminViewLog::PERSONAL_DATA_ACTIONS.all? { |a| AdminViewLog::ACTIONS.include?(a) }
    assert AdminViewLog::USER_MANAGEMENT_ACTIONS.all? { |a| AdminViewLog::ACTIONS.include?(a) }
    assert AdminViewLog::CONTENT_MANAGEMENT_ACTIONS.all? { |a| AdminViewLog::ACTIONS.include?(a) }
    assert AdminViewLog::SYSTEM_ACTIONS.all? { |a| AdminViewLog::ACTIONS.include?(a) }
  end

  test "SENSITIVE_ACTIONS are a subset of all actions" do
    AdminViewLog::SENSITIVE_ACTIONS.each do |action|
      assert AdminViewLog::ACTIONS.include?(action), "#{action} should be in ACTIONS"
    end
  end

  test "ACTIONS values are strings" do
    AdminViewLog::ACTIONS.each do |value|
      assert_kind_of String, value, "Action value should be a String"
      assert value.present?, "Action value should not be blank"
      assert_match /^[a-z_]+$/, value, "Action value should be snake_case"
    end
  end

  # ============================================================================
  # Enhanced Security Tests
  # ============================================================================

  test "log_action creates a new log entry" do
    assert_difference -> { AdminViewLog.count }, 1 do
      AdminViewLog.log_action(
        admin: @admin,
        action: :force_logout_session,
        target: @deletion,
        reason: "Testing audit log functionality"
      )
    end
  end

  test "log_action with metadata appends to reason" do
    log = AdminViewLog.log_action(
      admin: @admin,
      action: :delete_user_post,
      target: @deletion,
      reason: "Policy violation",
      metadata: { post_id: 123, title: "Test Post" }
    )

    assert_includes log.reason, "Policy violation"
    assert_includes log.reason, "post_id: 123"
    assert_includes log.reason, "title: Test Post"
  end

  test "log_action with request extracts IP and user agent" do
    require "ostruct"
    request_mock = ::OpenStruct.new(
      remote_ip: "192.168.1.100",
      user_agent: "Mozilla/5.0 Test"
    )

    log = AdminViewLog.log_action(
      admin: @admin,
      action: :reveal_personal_info,
      target: @deletion,
      reason: "Customer support request",
      request: request_mock
    )

    assert_equal "192.168.1.100", log.ip_address
    assert_equal "Mozilla/5.0 Test", log.user_agent
  end

  test "sensitive_action? returns true for sensitive actions" do
    AdminViewLog::SENSITIVE_ACTIONS.each do |action|
      assert AdminViewLog.sensitive_action?(action), "#{action} should be sensitive"
    end
  end

  test "sensitive_action? returns false for non-sensitive actions" do
    refute AdminViewLog.sensitive_action?("sudo_mode_enabled")
    refute AdminViewLog.sensitive_action?("nonexistent_action")
  end

  test "action_label returns Korean label" do
    log = AdminViewLog.create!(
      admin: @admin,
      target: @deletion,
      action: "force_logout_session",
      reason: "Test reason text"
    )

    assert_equal "세션 강제 종료", log.action_label
  end

  test "sensitive? returns true for sensitive action" do
    log = AdminViewLog.create!(
      admin: @admin,
      target: @deletion,
      action: "delete_user_post",
      reason: "Test reason text"
    )

    assert log.sensitive?
  end

  test "sensitive? returns false for non-sensitive action" do
    log = AdminViewLog.create!(
      admin: @admin,
      target: @deletion,
      action: "sudo_mode_enabled",
      reason: "Test reason text"
    )

    refute log.sensitive?
  end

  test "by_action scope filters correctly" do
    AdminViewLog.create!(
      admin: @admin,
      target: @deletion,
      action: "delete_user_post",
      reason: "Test delete post"
    )
    AdminViewLog.create!(
      admin: @admin,
      target: @deletion,
      action: "force_logout_session",
      reason: "Test logout"
    )

    delete_logs = AdminViewLog.by_action("delete_user_post")
    assert delete_logs.all? { |log| log.action == "delete_user_post" }
    assert_equal 1, delete_logs.count
  end

  test "sensitive_actions scope returns only sensitive actions" do
    AdminViewLog.create!(
      admin: @admin,
      target: @deletion,
      action: "delete_user_post", # sensitive
      reason: "Test sensitive action"
    )
    AdminViewLog.create!(
      admin: @admin,
      target: @deletion,
      action: "sudo_mode_enabled", # not sensitive
      reason: "Test non-sensitive"
    )

    sensitive_logs = AdminViewLog.sensitive_actions
    assert sensitive_logs.all?(&:sensitive?)
  end

  # ============================================================================
  # Optional Field Tests
  # ============================================================================

  test "stores ip_address" do
    log = AdminViewLog.create!(
      admin: @admin,
      target: @deletion,
      action: "reveal_personal_info",
      reason: "IP 저장 테스트입니다",
      ip_address: "192.168.1.100"
    )

    log.reload
    assert_equal "192.168.1.100", log.ip_address
  end

  test "stores user_agent" do
    log = AdminViewLog.create!(
      admin: @admin,
      target: @deletion,
      action: "reveal_personal_info",
      reason: "UA 저장 테스트입니다",
      user_agent: "Mozilla/5.0 Test Browser"
    )

    log.reload
    assert_equal "Mozilla/5.0 Test Browser", log.user_agent
  end

  test "ip_address and user_agent are optional" do
    log = AdminViewLog.new(
      admin: @admin,
      target: @deletion,
      action: "reveal_personal_info",
      reason: "필수 필드만 테스트"
    )
    assert log.valid?
  end

  # ============================================================================
  # Integration Tests
  # ============================================================================

  test "can be created via record_admin_view!" do
    assert_difference "AdminViewLog.count", 1 do
      @deletion.record_admin_view!(
        admin: @admin,
        reason: "통합 테스트 열람입니다"
      )
    end

    log = AdminViewLog.last
    assert_equal @admin, log.admin
    assert_equal @deletion, log.target
    assert_equal "reveal_personal_info", log.action
  end
end
