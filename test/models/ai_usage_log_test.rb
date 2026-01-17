# frozen_string_literal: true

require "test_helper"

class AiUsageLogTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  test "should create usage log" do
    log = AiUsageLog.create!(
      user: @user,
      idea_summary: "테스트 아이디어",
      status: :analyzing,
      is_real_analysis: true
    )

    assert log.persisted?
    assert_equal @user.id, log.user_id
    assert_equal "analyzing", log.status
    assert log.is_real_analysis
  end

  test "should have correct scopes" do
    # 오늘 기록
    today_log = AiUsageLog.create!(
      user: @user,
      idea_summary: "오늘 테스트",
      status: :completed
    )

    # 지난주 기록
    old_log = AiUsageLog.create!(
      user: @user,
      idea_summary: "오래된 테스트",
      status: :completed,
      created_at: 2.weeks.ago
    )

    assert_includes AiUsageLog.today, today_log
    assert_not_includes AiUsageLog.today, old_log

    assert_includes AiUsageLog.this_week, today_log
    assert_not_includes AiUsageLog.this_week, old_log
  end

  test "should calculate usage stats" do
    AiUsageLog.destroy_all

    3.times { AiUsageLog.create!(user: @user, status: :completed, is_real_analysis: true) }
    2.times { AiUsageLog.create!(user: @user, status: :failed, is_real_analysis: false) }

    stats = AiUsageLog.usage_stats

    assert_equal 5, stats[:total]
    assert_equal 3, stats[:completed]
    assert_equal 2, stats[:failed]
    assert_equal 3, stats[:real_analyses]
    assert_equal 2, stats[:mock_analyses]
  end

  test "should preserve log when idea_analysis is destroyed" do
    # IdeaAnalysis 생성 (자동으로 usage_log 생성됨)
    analysis = IdeaAnalysis.create!(
      user: @user,
      idea: "삭제 테스트 아이디어",
      analysis_result: { test: true },
      status: :completed,
      is_real_analysis: true
    )

    usage_log = analysis.ai_usage_log
    assert usage_log.present?
    log_id = usage_log.id

    # IdeaAnalysis 삭제
    analysis.destroy!

    # 사용 기록은 보존되어야 함
    preserved_log = AiUsageLog.find_by(id: log_id)
    assert preserved_log.present?
    assert_nil preserved_log.idea_analysis_id  # nullify 됨
    assert_equal "삭제 테스트 아이디어".truncate(200), preserved_log.idea_summary
  end

  test "should sync status when analysis is updated" do
    analysis = IdeaAnalysis.create!(
      user: @user,
      idea: "상태 동기화 테스트",
      analysis_result: {},
      status: :analyzing,
      is_real_analysis: true
    )

    usage_log = analysis.ai_usage_log
    assert_equal "analyzing", usage_log.status
    assert_nil usage_log.completed_at

    # 상태 완료로 변경
    analysis.update!(status: :completed, analysis_result: { test: true }, score: 85)

    usage_log.reload
    assert_equal "completed", usage_log.status
    assert_equal 85, usage_log.score
    assert usage_log.completed_at.present?
  end

  test "should sync was_saved when analysis is saved" do
    analysis = IdeaAnalysis.create!(
      user: @user,
      idea: "저장 동기화 테스트",
      analysis_result: { test: true },
      status: :completed,
      is_saved: false
    )

    usage_log = analysis.ai_usage_log
    assert_not usage_log.was_saved

    # 저장 상태 변경
    analysis.save_to_collection!

    usage_log.reload
    assert usage_log.was_saved
  end

  # ===== 추가 테스트 (2026-01-17) =====

  test "recent scope orders by created_at desc" do
    AiUsageLog.destroy_all

    old_log = AiUsageLog.create!(user: @user, status: :completed, created_at: 2.days.ago)
    new_log = AiUsageLog.create!(user: @user, status: :completed, created_at: 1.hour.ago)
    mid_log = AiUsageLog.create!(user: @user, status: :completed, created_at: 1.day.ago)

    recent_logs = AiUsageLog.recent
    assert_equal new_log.id, recent_logs.first.id
    assert_equal old_log.id, recent_logs.last.id
  end

  test "scopes chain correctly for filtering" do
    AiUsageLog.destroy_all

    # 오늘 + 실제 분석
    today_real = AiUsageLog.create!(user: @user, status: :completed, is_real_analysis: true)

    # 오늘 + mock 분석
    today_mock = AiUsageLog.create!(user: @user, status: :completed, is_real_analysis: false)

    # 지난주 + 실제 분석
    old_real = AiUsageLog.create!(
      user: @user,
      status: :completed,
      is_real_analysis: true,
      created_at: 2.weeks.ago
    )

    # 체이닝: 오늘 + 실제 분석
    result = AiUsageLog.today.real_analyses
    assert_includes result, today_real
    assert_not_includes result, today_mock
    assert_not_includes result, old_real
  end

  test "handles nil idea_summary gracefully" do
    log = AiUsageLog.create!(
      user: @user,
      idea_summary: nil,
      status: :analyzing
    )

    assert log.persisted?
    assert_nil log.idea_summary
  end

  test "handles nil score gracefully" do
    log = AiUsageLog.create!(
      user: @user,
      status: :completed,
      score: nil
    )

    assert log.persisted?
    assert_nil log.score
  end

  test "saved_by_user scope returns only saved logs" do
    AiUsageLog.destroy_all

    saved_log = AiUsageLog.create!(user: @user, status: :completed, was_saved: true)
    unsaved_log = AiUsageLog.create!(user: @user, status: :completed, was_saved: false)

    saved_logs = AiUsageLog.saved_by_user
    assert_includes saved_logs, saved_log
    assert_not_includes saved_logs, unsaved_log
  end

  test "usage_stats returns correct statistics" do
    AiUsageLog.destroy_all

    # 다양한 상태의 로그 생성
    AiUsageLog.create!(user: @user, status: :completed, is_real_analysis: true, was_saved: true)
    AiUsageLog.create!(user: @user, status: :completed, is_real_analysis: true, was_saved: false)
    AiUsageLog.create!(user: @user, status: :failed, is_real_analysis: false)
    AiUsageLog.create!(user: @user, status: :analyzing, is_real_analysis: true)

    stats = AiUsageLog.usage_stats

    assert_equal 4, stats[:total]
    assert_equal 2, stats[:completed]
    assert_equal 1, stats[:failed]
    assert_equal 3, stats[:real_analyses]
    assert_equal 1, stats[:mock_analyses]
    assert_equal 1, stats[:saved_by_user]
  end

  test "this_month scope includes all logs from current month" do
    AiUsageLog.destroy_all

    # 이번 달 기록
    this_month_log = AiUsageLog.create!(
      user: @user,
      status: :completed,
      created_at: 2.weeks.ago
    )

    # 지난 달 기록
    last_month_log = AiUsageLog.create!(
      user: @user,
      status: :completed,
      created_at: 2.months.ago
    )

    this_month_logs = AiUsageLog.this_month
    assert_includes this_month_logs, this_month_log
    assert_not_includes this_month_logs, last_month_log
  end

  test "status enum provides correct methods" do
    log = AiUsageLog.create!(user: @user, status: :analyzing)

    assert log.analyzing?
    assert_not log.completed?
    assert_not log.failed?

    log.completed!
    assert log.completed?
    assert_not log.analyzing?
  end
end
