# frozen_string_literal: true

class IdeaAnalysis < ApplicationRecord
  belongs_to :user

  # 상태 enum (비동기 분석용)
  enum :status, {
    analyzing: "analyzing",
    completed: "completed",
    failed: "failed"
  }, default: :completed

  # 분석 단계 상수
  TOTAL_STAGES = 5

  STAGE_NAMES = {
    0 => "준비 중",
    1 => "아이디어 요약 분석",
    2 => "타겟 사용자 분석",
    3 => "시장 분석",
    4 => "전략 도출",
    5 => "점수 계산",
    6 => "완료"
  }.freeze

  validates :idea, presence: true
  # analysis_result는 completed 상태에서만 필수
  # analyzing, failed 상태에서는 비어있을 수 있음
  validates :analysis_result, presence: true, if: :completed?

  # 최신순 정렬
  scope :recent, -> { order(created_at: :desc) }

  # 분석 완료 시 Turbo Stream 브로드캐스트
  after_update_commit :broadcast_completion, if: :should_broadcast_completion?

  # 분석 단계 업데이트 및 진행률 브로드캐스트
  def update_stage!(stage_number)
    update!(current_stage: stage_number)
    broadcast_progress
  end

  private

  def should_broadcast_completion?
    saved_change_to_status? && completed?
  end

  # 진행률 브로드캐스트 (단계 변경 시)
  def broadcast_progress
    Rails.logger.info "[IdeaAnalysis##{id}] Broadcasting progress: stage #{current_stage}/#{TOTAL_STAGES}"

    broadcast_update_to "idea_analysis_#{id}",
                        target: "ai_loading_progress",
                        partial: "onboarding/loading_progress",
                        locals: {
                          current_stage: current_stage,
                          total_stages: TOTAL_STAGES,
                          stage_name: STAGE_NAMES[current_stage]
                        }
  end

  def broadcast_completion
    Rails.logger.info "[IdeaAnalysis##{id}] Broadcasting completion via Turbo Stream"

    broadcast_replace_to "idea_analysis_#{id}",
                         target: "ai_result_content",
                         partial: "onboarding/ai_result_content",
                         locals: {
                           idea_analysis: self,
                           analysis: parsed_result,
                           recommended_experts: find_recommended_experts_for_broadcast
                         }
  end

  # 브로드캐스트용 추천 전문가 찾기
  def find_recommended_experts_for_broadcast
    required_expertise = parsed_result[:required_expertise] || default_required_expertise

    experts = ExpertMatcher.new(
      required_expertise,
      exclude_user_id: user_id
    ).find_matches

    # 점수 향상 예측
    predictor = Ai::ExpertScorePredictor.new(parsed_result)
    predictor.predict_all(experts)
  end

  def default_required_expertise
    {
      roles: [],
      skills: [],
      description: ""
    }
  end

  public

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
