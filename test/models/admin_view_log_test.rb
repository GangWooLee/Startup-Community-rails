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

  test "ACTIONS contains expected values" do
    expected = {
      reveal_personal_info: "reveal_personal_info",
      view_snapshot: "view_snapshot",
      export_data: "export_data"
    }
    assert_equal expected, AdminViewLog::ACTIONS, "ACTIONS hash should match expected structure"
    assert_equal 3, AdminViewLog::ACTIONS.size, "Should have exactly 3 actions"
    assert AdminViewLog::ACTIONS.key?(:reveal_personal_info), "Should include reveal_personal_info"
    assert AdminViewLog::ACTIONS.key?(:view_snapshot), "Should include view_snapshot"
    assert AdminViewLog::ACTIONS.key?(:export_data), "Should include export_data"
  end

  test "ACTIONS values are strings" do
    AdminViewLog::ACTIONS.values.each do |value|
      assert_kind_of String, value, "Action value should be a String"
      assert value.present?, "Action value should not be blank"
      assert_match /^[a-z_]+$/, value, "Action value should be snake_case"
    end
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
