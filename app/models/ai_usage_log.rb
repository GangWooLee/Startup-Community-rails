# frozen_string_literal: true

# AI 분석 사용 기록 (영구 보존)
# - IdeaAnalysis가 삭제되어도 사용 기록은 유지됨
# - 통계 및 사용량 추적 목적
class AiUsageLog < ApplicationRecord
  belongs_to :user
  belongs_to :idea_analysis, optional: true  # 분석 삭제 후에도 로그는 유지

  # 상태 enum
  enum :status, {
    analyzing: "analyzing",
    completed: "completed",
    failed: "failed"
  }, default: :analyzing

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where("created_at >= ?", Time.current.beginning_of_day) }
  scope :this_week, -> { where("created_at >= ?", 1.week.ago) }
  scope :this_month, -> { where("created_at >= ?", 1.month.ago) }
  scope :real_analyses, -> { where(is_real_analysis: true) }
  scope :mock_analyses, -> { where(is_real_analysis: false) }
  scope :saved_by_user, -> { where(was_saved: true) }

  # IdeaAnalysis에서 사용 기록 생성
  def self.log_from_analysis(analysis)
    create!(
      user_id: analysis.user_id,
      idea_summary: analysis.idea.to_s.truncate(200),
      status: analysis.status,
      is_real_analysis: analysis.is_real_analysis,
      score: analysis.score,
      completed_at: analysis.completed? ? Time.current : nil,
      idea_analysis_id: analysis.id,
      was_saved: analysis.is_saved
    )
  end

  # 기존 IdeaAnalysis에서 사용 기록 생성 (마이그레이션용)
  def self.backfill_from_analyses
    IdeaAnalysis.find_each do |analysis|
      next if exists?(idea_analysis_id: analysis.id)

      create!(
        user_id: analysis.user_id,
        idea_summary: analysis.idea.to_s.truncate(200),
        status: analysis.status,
        is_real_analysis: analysis.is_real_analysis,
        score: analysis.score,
        completed_at: analysis.completed? ? analysis.updated_at : nil,
        idea_analysis_id: analysis.id,
        was_saved: analysis.is_saved,
        created_at: analysis.created_at,
        updated_at: analysis.updated_at
      )
    end
  end

  # 통계 헬퍼 메서드
  def self.usage_stats(scope = all)
    {
      total: scope.count,
      today: scope.today.count,
      this_week: scope.this_week.count,
      this_month: scope.this_month.count,
      real_analyses: scope.real_analyses.count,
      mock_analyses: scope.mock_analyses.count,
      completed: scope.completed.count,
      failed: scope.failed.count,
      saved_by_user: scope.saved_by_user.count
    }
  end

  # 날짜별 사용량 (차트용)
  def self.daily_usage(days: 30)
    where("created_at >= ?", days.days.ago)
      .group("DATE(created_at)")
      .count
  end
end
