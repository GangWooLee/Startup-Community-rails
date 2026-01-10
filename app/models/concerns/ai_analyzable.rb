# frozen_string_literal: true

# AI 분석 사용량 관리 기능
# 사용: include AiAnalyzable
#
# 제공 메서드:
# - effective_ai_limit: 사용자의 유효 AI 분석 limit
# - ai_analyses_remaining: 남은 AI 분석 횟수 (보너스 포함)
# - base_remaining: 보너스 제외 기본 잔여 횟수
# - ai_limit_reached?: AI 분석 limit에 도달했는지 확인
# - calculate_bonus_for_remaining(desired): 원하는 잔여횟수를 위한 보너스 계산
# - ai_usage_stats: AI 분석 사용량 통계 (관리자용)
module AiAnalyzable
  extend ActiveSupport::Concern

  included do
    # AI 분석 사용량 제한 (관리자 설정 가능)
    DEFAULT_AI_ANALYSIS_LIMIT = 5
  end

  # 사용자의 유효 AI 분석 limit 반환 (nil이면 기본값 사용)
  def effective_ai_limit
    ai_analysis_limit || DEFAULT_AI_ANALYSIS_LIMIT
  end

  # 남은 AI 분석 횟수 반환 (보너스 포함)
  # remaining = limit - used + bonus
  def ai_analyses_remaining
    [ effective_ai_limit - idea_analyses.count + ai_bonus_credits.to_i, 0 ].max
  end

  # 보너스 제외 기본 잔여 횟수
  def base_remaining
    [ effective_ai_limit - idea_analyses.count, 0 ].max
  end

  # AI 분석 limit에 도달했는지 확인
  def ai_limit_reached?
    ai_analyses_remaining <= 0
  end

  # 원하는 잔여횟수를 설정하기 위해 필요한 보너스 계산
  def calculate_bonus_for_remaining(desired_remaining)
    base = effective_ai_limit - idea_analyses.count
    desired_remaining - base
  end

  # AI 분석 사용량 통계 (관리자용)
  def ai_usage_stats
    {
      used: idea_analyses.count,
      limit: effective_ai_limit,
      bonus: ai_bonus_credits.to_i,
      remaining: ai_analyses_remaining,
      base_remaining: base_remaining,
      is_custom_limit: ai_analysis_limit.present?,
      has_bonus: ai_bonus_credits.to_i > 0,
      reached: ai_limit_reached?
    }
  end
end
