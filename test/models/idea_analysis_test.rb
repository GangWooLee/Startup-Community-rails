# frozen_string_literal: true

require "test_helper"

class IdeaAnalysisTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  # ─────────────────────────────────────────────────
  # Association Tests
  # ─────────────────────────────────────────────────

  test "belongs to user" do
    analysis = IdeaAnalysis.new(
      user: @user,
      idea: "테스트 아이디어",
      analysis_result: { summary: "테스트" }
    )
    assert_equal @user, analysis.user
  end

  # ─────────────────────────────────────────────────
  # Validation Tests
  # ─────────────────────────────────────────────────

  test "valid idea analysis" do
    analysis = IdeaAnalysis.new(
      user: @user,
      idea: "테스트 아이디어",
      analysis_result: { summary: "테스트" }
    )
    assert analysis.valid?
  end

  test "requires idea" do
    analysis = IdeaAnalysis.new(user: @user, analysis_result: { summary: "테스트" })
    assert_not analysis.valid?
    assert analysis.errors[:idea].any?
  end

  test "requires analysis_result when completed" do
    analysis = IdeaAnalysis.new(
      user: @user,
      idea: "테스트 아이디어",
      status: :completed
    )
    assert_not analysis.valid?
    assert analysis.errors[:analysis_result].any?
  end

  test "allows empty analysis_result when analyzing" do
    analysis = IdeaAnalysis.new(
      user: @user,
      idea: "테스트 아이디어",
      status: :analyzing
    )
    assert analysis.valid?
  end

  test "allows empty analysis_result when failed" do
    analysis = IdeaAnalysis.new(
      user: @user,
      idea: "테스트 아이디어",
      status: :failed
    )
    assert analysis.valid?
  end

  # ─────────────────────────────────────────────────
  # Status Enum Tests
  # ─────────────────────────────────────────────────

  test "default status is completed" do
    analysis = IdeaAnalysis.new(user: @user, idea: "테스트", analysis_result: {})
    assert analysis.completed?
  end

  test "status can be analyzing" do
    analysis = IdeaAnalysis.new(user: @user, idea: "테스트", status: :analyzing)
    assert analysis.analyzing?
  end

  test "status can be failed" do
    analysis = IdeaAnalysis.new(user: @user, idea: "테스트", status: :failed, analysis_result: {})
    assert analysis.failed?
  end

  # ─────────────────────────────────────────────────
  # Scope Tests
  # ─────────────────────────────────────────────────

  test "recent scope orders by created_at desc" do
    old = IdeaAnalysis.create!(user: @user, idea: "Old Test", analysis_result: { summary: "old" }, created_at: 2.days.ago)
    new = IdeaAnalysis.create!(user: @user, idea: "New Test", analysis_result: { summary: "new" }, created_at: 1.day.ago)

    # 생성한 레코드들만 필터링하여 순서 확인
    results = IdeaAnalysis.recent.where(id: [ old.id, new.id ])
    assert_equal new, results.first
    assert_equal old, results.last
  end

  test "expired_unsaved scope returns unsaved analyses older than 7 days" do
    # 8일 전 미저장 분석 - 만료됨
    expired_analysis = IdeaAnalysis.create!(
      user: @user,
      idea: "Expired unsaved",
      analysis_result: { summary: "test" },
      is_saved: false
    )
    expired_analysis.update_column(:updated_at, 8.days.ago)

    # 6일 전 미저장 분석 - 아직 유효
    recent_analysis = IdeaAnalysis.create!(
      user: @user,
      idea: "Recent unsaved",
      analysis_result: { summary: "test" },
      is_saved: false
    )
    recent_analysis.update_column(:updated_at, 6.days.ago)

    # 8일 전 저장된 분석 - 만료 대상 아님
    saved_analysis = IdeaAnalysis.create!(
      user: @user,
      idea: "Saved analysis",
      analysis_result: { summary: "test" },
      is_saved: true
    )
    saved_analysis.update_column(:updated_at, 8.days.ago)

    expired_ids = IdeaAnalysis.expired_unsaved.pluck(:id)

    # 8일 전 미저장 분석만 만료 대상
    assert_includes expired_ids, expired_analysis.id
    assert_not_includes expired_ids, recent_analysis.id
    assert_not_includes expired_ids, saved_analysis.id
  end

  test "saved scope returns only saved analyses" do
    saved = IdeaAnalysis.create!(user: @user, idea: "Saved", analysis_result: { summary: "test" }, is_saved: true)
    unsaved = IdeaAnalysis.create!(user: @user, idea: "Unsaved", analysis_result: { summary: "test" }, is_saved: false)

    saved_ids = IdeaAnalysis.saved.where(id: [ saved.id, unsaved.id ]).pluck(:id)
    assert_includes saved_ids, saved.id
    assert_not_includes saved_ids, unsaved.id
  end

  test "unsaved scope returns only unsaved analyses" do
    saved = IdeaAnalysis.create!(user: @user, idea: "Saved", analysis_result: { summary: "test" }, is_saved: true)
    unsaved = IdeaAnalysis.create!(user: @user, idea: "Unsaved", analysis_result: { summary: "test" }, is_saved: false)

    unsaved_ids = IdeaAnalysis.unsaved.where(id: [ saved.id, unsaved.id ]).pluck(:id)
    assert_not_includes unsaved_ids, saved.id
    assert_includes unsaved_ids, unsaved.id
  end

  # ─────────────────────────────────────────────────
  # Parsed Result Helpers Tests
  # ─────────────────────────────────────────────────

  test "parsed_result returns symbolized hash" do
    analysis = IdeaAnalysis.new(
      user: @user,
      idea: "테스트",
      analysis_result: { "summary" => "테스트 요약", "score" => { "overall" => 70 } }
    )

    result = analysis.parsed_result
    assert result.is_a?(Hash)
    assert_equal "테스트 요약", result[:summary]
    assert_equal 70, result[:score][:overall]
  end

  test "summary returns summary from parsed_result" do
    analysis = IdeaAnalysis.new(
      user: @user,
      idea: "테스트",
      analysis_result: { summary: "아이디어 요약입니다" }
    )
    assert_equal "아이디어 요약입니다", analysis.summary
  end

  test "target_users returns target_users from parsed_result" do
    target_users = { primary: "대학생", characteristics: [ "학습 의지" ] }
    analysis = IdeaAnalysis.new(
      user: @user,
      idea: "테스트",
      analysis_result: { target_users: target_users }
    )
    assert_equal "대학생", analysis.target_users[:primary]
  end

  test "score_data returns score from parsed_result" do
    analysis = IdeaAnalysis.new(
      user: @user,
      idea: "테스트",
      analysis_result: { score: { overall: 75, weak_areas: [ "시장 분석" ] } }
    )
    assert_equal 75, analysis.score_data[:overall]
  end

  test "actions returns actions from parsed_result" do
    actions = [ { title: "MVP 개발" }, { title: "팀 구성" } ]
    analysis = IdeaAnalysis.new(
      user: @user,
      idea: "테스트",
      analysis_result: { actions: actions }
    )
    assert_equal 2, analysis.actions.size
  end

  # ─────────────────────────────────────────────────
  # Constants Tests
  # ─────────────────────────────────────────────────

  test "TOTAL_STAGES is 5" do
    assert_equal 5, IdeaAnalysis::TOTAL_STAGES
  end

  test "STAGE_NAMES contains all stages" do
    names = IdeaAnalysis::STAGE_NAMES
    assert_equal "준비 중", names[0]
    assert_equal "아이디어 요약 분석", names[1]
    assert_equal "완료", names[6]
  end

  # ─────────────────────────────────────────────────
  # Update Stage Tests
  # ─────────────────────────────────────────────────

  test "update_stage! updates current_stage" do
    analysis = IdeaAnalysis.create!(
      user: @user,
      idea: "테스트",
      status: :analyzing,
      current_stage: 0,
      analysis_result: {}  # DB NOT NULL 제약조건
    )

    analysis.update_stage!(3)
    assert_equal 3, analysis.reload.current_stage
  end
end
