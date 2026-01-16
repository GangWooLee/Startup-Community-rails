# frozen_string_literal: true

require "test_helper"

class CleanupOldSessionsJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
  end

  test "deletes sessions older than 90 days" do
    # 오래된 세션 생성
    old_session = UserSession.record_login(user: @user, method: "email")
    old_session.update!(logged_in_at: 91.days.ago)

    # 최근 세션 생성
    recent_session = UserSession.record_login(user: @user, method: "email")

    assert_equal 2, UserSession.count

    result = CleanupOldSessionsJob.perform_now

    assert_equal 1, result[:deleted]
    assert_equal 90, result[:retention_days]
    assert_equal 1, UserSession.count
    assert_equal recent_session.id, UserSession.first.id
  end

  test "does not delete sessions within 90 days" do
    # 89일 된 세션 (삭제되면 안 됨)
    session = UserSession.record_login(user: @user, method: "email")
    session.update!(logged_in_at: 89.days.ago)

    result = CleanupOldSessionsJob.perform_now

    assert_equal 0, result[:deleted]
    assert_equal 1, UserSession.count
  end

  test "handles empty table gracefully" do
    UserSession.delete_all

    result = CleanupOldSessionsJob.perform_now

    assert_equal 0, result[:deleted]
  end

  test "deletes multiple old sessions in batch" do
    # 100개의 오래된 세션 생성
    10.times do
      session = UserSession.record_login(user: @user, method: "email")
      session.update!(logged_in_at: 100.days.ago)
    end

    result = CleanupOldSessionsJob.perform_now

    assert_equal 10, result[:deleted]
    assert_equal 0, UserSession.count
  end
end
