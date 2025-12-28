# frozen_string_literal: true

class IdeaAnalysis < ApplicationRecord
  belongs_to :user

  validates :idea, presence: true
  validates :analysis_result, presence: true

  # 최신순 정렬
  scope :recent, -> { order(created_at: :desc) }

  # JSON 필드 접근 헬퍼 (symbolize_keys 적용)
  def parsed_result
    @parsed_result ||= (analysis_result || {}).deep_symbolize_keys
  end

  def summary
    parsed_result[:summary]
  end

  def target_users
    parsed_result[:target_users]
  end

  def market_analysis
    parsed_result[:market_analysis]
  end

  def recommendations
    parsed_result[:recommendations]
  end

  def score_data
    parsed_result[:score]
  end

  def actions
    parsed_result[:actions]
  end

  def required_expertise
    parsed_result[:required_expertise]
  end

  def metadata
    parsed_result[:metadata]
  end
end
