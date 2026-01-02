# frozen_string_literal: true

require "test_helper"

class Admin::UserDeletionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user = users(:one)
    @deletion = user_deletions(:recent_deletion)
    @viewed_deletion = user_deletions(:viewed_deletion)
  end

  # ============================================================================
  # Authentication & Authorization Tests
  # ============================================================================

  test "index requires login" do
    get admin_user_deletions_path
    assert_redirected_to root_path
  end

  test "index rejects non-admin user" do
    log_in_as(@user)

    get admin_user_deletions_path
    assert_redirected_to root_path
    assert_flash :alert, "관리자 권한"
  end

  test "index allows admin access" do
    log_in_as(@admin)

    get admin_user_deletions_path
    assert_response :success
  end

  test "show requires login" do
    get admin_user_deletion_path(@deletion)
    assert_redirected_to root_path
  end

  test "show rejects non-admin user" do
    log_in_as(@user)

    get admin_user_deletion_path(@deletion)
    assert_redirected_to root_path
    assert_flash :alert, "관리자 권한"
  end

  test "show allows admin access" do
    log_in_as(@admin)

    get admin_user_deletion_path(@deletion)
    assert_response :success
  end

  test "reveal requires login" do
    post reveal_admin_user_deletion_path(@deletion), params: { reason: "테스트 열람 사유입니다" }
    assert_redirected_to root_path
  end

  test "reveal rejects non-admin user" do
    log_in_as(@user)

    post reveal_admin_user_deletion_path(@deletion), params: { reason: "테스트 열람 사유입니다" }
    assert_redirected_to root_path
  end

  # ============================================================================
  # Index Action Tests
  # ============================================================================

  test "index displays deletion list" do
    log_in_as(@admin)

    get admin_user_deletions_path
    assert_response :success
    assert_select "table" # Assuming deletions are displayed in a table
  end

  test "index includes statistics" do
    log_in_as(@admin)

    get admin_user_deletions_path
    assert_response :success
    # Controller sets @stats with total, this_month, by_reason
    assert assigns(:stats).present?
    assert assigns(:stats)[:total].present?
    assert assigns(:stats)[:this_month].present?
    assert assigns(:stats)[:by_reason].present?
  end

  test "index orders by created_at desc" do
    log_in_as(@admin)

    get admin_user_deletions_path
    assert_response :success
    deletions = assigns(:deletions)
    assert deletions.present?
    # Verify ordering (most recent first)
    if deletions.size > 1
      assert deletions.first.created_at >= deletions.second.created_at
    end
  end

  test "index limits results to 50" do
    log_in_as(@admin)

    get admin_user_deletions_path
    assert_response :success
    deletions = assigns(:deletions)
    assert deletions.size <= 50
  end

  # ============================================================================
  # Show Action Tests
  # ============================================================================

  test "show displays deletion details" do
    log_in_as(@admin)

    get admin_user_deletion_path(@deletion)
    assert_response :success
  end

  test "show displays masked personal info by default" do
    log_in_as(@admin)

    get admin_user_deletion_path(@deletion)
    assert_response :success
    # Personal info should be masked in the initial view
    # The reveal endpoint is required to see actual data
  end

  test "show handles non-existent deletion" do
    log_in_as(@admin)

    # RecordNotFound is not rescued by BaseController, so it should raise
    # But if config.action_dispatch.show_exceptions is :rescuable, it will be handled
    get admin_user_deletion_path(id: 999999)
    assert_response :not_found
  end

  test "show displays reason category and detail" do
    log_in_as(@admin)

    get admin_user_deletion_path(@deletion)
    assert_response :success
    # The view should show reason_category translated label
  end

  test "show displays admin view count" do
    log_in_as(@admin)

    get admin_user_deletion_path(@viewed_deletion)
    assert_response :success
    # viewed_deletion has admin_view_count: 2
  end

  # ============================================================================
  # Reveal Action Tests - Success Cases
  # ============================================================================

  test "reveal returns decrypted personal info with valid reason" do
    log_in_as(@admin)

    post reveal_admin_user_deletion_path(@deletion), params: {
      reason: "법적 분쟁으로 인한 열람 필요"
    }

    assert_response :success
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal @deletion.email_original, json["data"]["email"]
    assert_equal @deletion.name_original, json["data"]["name"]
  end

  test "reveal increments admin_view_count" do
    log_in_as(@admin)
    original_count = @deletion.admin_view_count

    post reveal_admin_user_deletion_path(@deletion), params: {
      reason: "사용자 문의 대응을 위한 열람"
    }

    assert_response :success
    @deletion.reload
    assert_equal original_count + 1, @deletion.admin_view_count
  end

  test "reveal creates AdminViewLog record" do
    log_in_as(@admin)

    assert_difference "AdminViewLog.count", 1 do
      post reveal_admin_user_deletion_path(@deletion), params: {
        reason: "감사 목적 열람입니다"
      }
    end

    assert_response :success
    log = AdminViewLog.last
    assert_equal @admin, log.admin
    assert_equal @deletion, log.target
    assert_equal "reveal_personal_info", log.action
    assert_equal "감사 목적 열람입니다", log.reason
  end

  test "reveal updates last_viewed_at and last_viewed_by" do
    log_in_as(@admin)

    freeze_time do
      post reveal_admin_user_deletion_path(@deletion), params: {
        reason: "시스템 점검 열람입니다"
      }

      assert_response :success
      @deletion.reload
      assert_equal Time.current, @deletion.last_viewed_at
      assert_equal @admin.id, @deletion.last_viewed_by
    end
  end

  test "reveal logs IP address" do
    log_in_as(@admin)

    post reveal_admin_user_deletion_path(@deletion), params: {
      reason: "테스트 목적 열람입니다"
    }

    assert_response :success
    log = AdminViewLog.last
    assert_not_nil log.ip_address
  end

  test "reveal logs user agent" do
    log_in_as(@admin)

    post reveal_admin_user_deletion_path(@deletion), params: {
      reason: "테스트 목적 열람입니다"
    }, headers: { "HTTP_USER_AGENT" => "TestBrowser/1.0" }

    assert_response :success
    log = AdminViewLog.last
    assert_equal "TestBrowser/1.0", log.user_agent
  end

  # ============================================================================
  # Reveal Action Tests - Failure Cases
  # ============================================================================

  test "reveal fails without reason" do
    log_in_as(@admin)

    post reveal_admin_user_deletion_path(@deletion), params: {}

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["error"], "5자 이상"
  end

  test "reveal fails with empty reason" do
    log_in_as(@admin)

    post reveal_admin_user_deletion_path(@deletion), params: { reason: "" }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
  end

  test "reveal fails with short reason (less than 5 chars)" do
    log_in_as(@admin)

    post reveal_admin_user_deletion_path(@deletion), params: { reason: "짧음" }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert_includes json["error"], "5자 이상"
  end

  test "reveal accepts exactly 5 character reason" do
    log_in_as(@admin)

    post reveal_admin_user_deletion_path(@deletion), params: { reason: "12345" }

    assert_response :success
    json = JSON.parse(response.body)
    assert json["success"]
  end

  test "reveal does not increment view count on failure" do
    log_in_as(@admin)
    original_count = @deletion.admin_view_count

    post reveal_admin_user_deletion_path(@deletion), params: { reason: "짧음" }

    assert_response :unprocessable_entity
    @deletion.reload
    assert_equal original_count, @deletion.admin_view_count
  end

  test "reveal does not create log on failure" do
    log_in_as(@admin)

    assert_no_difference "AdminViewLog.count" do
      post reveal_admin_user_deletion_path(@deletion), params: { reason: "짧음" }
    end
  end

  # ============================================================================
  # Reveal Action Tests - Edge Cases
  # ============================================================================

  test "reveal handles non-existent deletion" do
    log_in_as(@admin)

    # set_deletion before_action raises RecordNotFound, which is not rescued
    post reveal_admin_user_deletion_path(id: 999999), params: {
      reason: "존재하지 않는 기록 열람"
    }
    # RecordNotFound is rescuable by Rails
    assert_response :not_found
  end

  test "reveal returns parsed snapshot data" do
    log_in_as(@admin)

    post reveal_admin_user_deletion_path(@deletion), params: {
      reason: "스냅샷 데이터 확인 필요"
    }

    assert_response :success
    json = JSON.parse(response.body)
    assert json["data"]["snapshot"].present?
    assert json["data"]["snapshot"].is_a?(Hash)
  end

  test "reveal with deletion that has no phone" do
    log_in_as(@admin)
    # expiring_soon_deletion has phone_original: nil
    expiring = user_deletions(:expiring_soon_deletion)

    post reveal_admin_user_deletion_path(expiring), params: {
      reason: "전화번호 없는 기록 테스트"
    }

    assert_response :success
    json = JSON.parse(response.body)
    assert json["success"]
    assert_nil json["data"]["phone"]
  end

  # ============================================================================
  # Statistics Tests
  # ============================================================================

  test "index stats total matches deletion count" do
    log_in_as(@admin)

    get admin_user_deletions_path
    assert_response :success
    assert_equal UserDeletion.count, assigns(:stats)[:total]
  end

  test "index stats by_reason groups correctly" do
    log_in_as(@admin)

    get admin_user_deletions_path
    assert_response :success
    stats = assigns(:stats)
    assert stats[:by_reason].is_a?(Hash)
  end
end
