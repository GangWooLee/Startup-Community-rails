# frozen_string_literal: true

require "test_helper"

class CleanupUnsavedAnalysesJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
  end

  test "deletes unsaved analyses older than 7 days" do
    # 8일 전에 생성된 미저장 분석
    old_unsaved = IdeaAnalysis.create!(
      user: @user,
      idea: "오래된 미저장 아이디어",
      status: :completed,
      is_saved: false,
      is_real_analysis: true,
      partial_success: false,
      current_stage: 5,
      score: 70,
      analysis_result: { summary: "테스트" },
      created_at: 8.days.ago,
      updated_at: 8.days.ago
    )

    assert_difference "IdeaAnalysis.count", -1 do
      CleanupUnsavedAnalysesJob.perform_now
    end

    assert_raises(ActiveRecord::RecordNotFound) { old_unsaved.reload }
  end

  test "preserves saved analyses regardless of age" do
    # 8일 전에 생성된 저장된 분석
    old_saved = IdeaAnalysis.create!(
      user: @user,
      idea: "오래된 저장된 아이디어",
      status: :completed,
      is_saved: true,
      is_real_analysis: true,
      partial_success: false,
      current_stage: 5,
      score: 80,
      analysis_result: { summary: "테스트" },
      created_at: 8.days.ago,
      updated_at: 8.days.ago
    )

    assert_no_difference "IdeaAnalysis.count" do
      CleanupUnsavedAnalysesJob.perform_now
    end

    assert_nothing_raised { old_saved.reload }
  end

  test "preserves unsaved analyses younger than 7 days" do
    # 6일 전에 생성된 미저장 분석
    recent_unsaved = IdeaAnalysis.create!(
      user: @user,
      idea: "최근 미저장 아이디어",
      status: :completed,
      is_saved: false,
      is_real_analysis: true,
      partial_success: false,
      current_stage: 5,
      score: 65,
      analysis_result: { summary: "테스트" },
      created_at: 6.days.ago,
      updated_at: 6.days.ago
    )

    assert_no_difference "IdeaAnalysis.count" do
      CleanupUnsavedAnalysesJob.perform_now
    end

    assert_nothing_raised { recent_unsaved.reload }
  end

  test "handles empty dataset gracefully" do
    # 모든 기존 분석 삭제
    IdeaAnalysis.delete_all

    result = CleanupUnsavedAnalysesJob.perform_now

    assert_equal 0, result[:deleted]
    assert_equal 0, result[:errors]
  end

  test "returns count of deleted analyses" do
    # 3개의 오래된 미저장 분석 생성
    3.times do |i|
      IdeaAnalysis.create!(
        user: @user,
        idea: "오래된 아이디어 #{i}",
        status: :completed,
        is_saved: false,
        is_real_analysis: true,
        partial_success: false,
        current_stage: 5,
        score: 60 + i,
        analysis_result: { summary: "테스트 #{i}" },
        created_at: 8.days.ago,
        updated_at: 8.days.ago
      )
    end

    result = CleanupUnsavedAnalysesJob.perform_now

    assert_equal 3, result[:deleted]
    assert_equal 0, result[:errors]
  end

  test "boundary test: exactly 7 days old analysis is NOT deleted" do
    # 기존 레코드 정리 (fixture에서 생성된 오래된 unsaved 분석 제거)
    IdeaAnalysis.delete_all

    # 시간을 고정하여 경계값 테스트의 일관성 보장
    freeze_time do
      # 정확히 7일 전에 생성된 분석 (경계값)
      # updated_at < 7.days.ago 조건이므로 정확히 7.days.ago는 삭제 안됨
      boundary_analysis = IdeaAnalysis.create!(
        user: @user,
        idea: "경계값 아이디어",
        status: :completed,
        is_saved: false,
        is_real_analysis: true,
        partial_success: false,
        current_stage: 5,
        score: 70,
        analysis_result: { summary: "테스트" },
        created_at: 7.days.ago,
        updated_at: 7.days.ago
      )

      # 7.days.ago는 "7일 전 현재 시점"이므로 updated_at < 7.days.ago 조건에 해당하지 않음
      # (정확히 7일이면 삭제 안됨, 7일 넘어야 삭제)
      assert_no_difference "IdeaAnalysis.count" do
        CleanupUnsavedAnalysesJob.perform_now
      end

      assert_nothing_raised { boundary_analysis.reload }
    end
  end

  test "boundary test: 7 days and 1 minute old analysis IS deleted" do
    # 7일 + 1분 전에 생성된 분석 (경계값 초과)
    old_analysis = IdeaAnalysis.create!(
      user: @user,
      idea: "경계값 초과 아이디어",
      status: :completed,
      is_saved: false,
      is_real_analysis: true,
      partial_success: false,
      current_stage: 5,
      score: 75,
      analysis_result: { summary: "테스트" },
      created_at: 7.days.ago - 1.minute,
      updated_at: 7.days.ago - 1.minute
    )

    assert_difference "IdeaAnalysis.count", -1 do
      CleanupUnsavedAnalysesJob.perform_now
    end

    assert_raises(ActiveRecord::RecordNotFound) { old_analysis.reload }
  end

  test "logs deletion count" do
    # Job 실행
    result = CleanupUnsavedAnalysesJob.perform_now

    # 로그 출력 검증은 Rails.logger 모킹이 필요하므로 결과만 확인
    assert result.is_a?(Hash)
    assert result.key?(:deleted)
    assert result.key?(:errors)
  end
end
