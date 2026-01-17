# frozen_string_literal: true

class IdeaAnalysis < ApplicationRecord
  belongs_to :user
  has_one :ai_usage_log, dependent: :nullify  # 삭제 시 로그는 보존 (nullify)

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

  # 저장 상태 scopes
  scope :saved, -> { where(is_saved: true) }
  scope :unsaved, -> { where(is_saved: false) }
  scope :expired_unsaved, -> { unsaved.where("updated_at < ?", 30.minutes.ago) }

  # 사용 기록 자동 생성/업데이트 (삭제되어도 기록은 보존됨)
  after_create :create_usage_log
  after_update :sync_usage_log, if: :should_sync_usage_log?

  # 분석 완료 시 Turbo Stream 브로드캐스트
  after_update_commit :broadcast_completion, if: :should_broadcast_completion?

  # 분석 단계 업데이트 및 진행률 브로드캐스트
  def update_stage!(stage_number)
    update!(current_stage: stage_number)
    broadcast_progress
  end

  private

  # 사용 기록 생성 (분석 시작 시)
  def create_usage_log
    AiUsageLog.create!(
      user_id: user_id,
      idea_summary: idea.to_s.truncate(200),
      status: status,
      is_real_analysis: is_real_analysis,
      score: score,
      idea_analysis_id: id
    )
  rescue StandardError => e
    Rails.logger.error "[IdeaAnalysis##{id}] Failed to create usage log: #{e.message}"
    # 사용 기록 생성 실패해도 분석은 계속 진행
  end

  # 사용 기록 동기화 (상태/저장 여부 변경 시)
  def sync_usage_log
    return unless ai_usage_log

    ai_usage_log.update!(
      status: status,
      score: score,
      completed_at: completed? ? Time.current : nil,
      was_saved: is_saved
    )
  rescue StandardError => e
    Rails.logger.error "[IdeaAnalysis##{id}] Failed to sync usage log: #{e.message}"
  end

  # 사용 기록 동기화가 필요한지 확인
  def should_sync_usage_log?
    saved_change_to_status? || saved_change_to_is_saved? || saved_change_to_score?
  end

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

  # 사용자가 명시적으로 저장할 때 호출
  def save_to_collection!
    update!(is_saved: true)
  end

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
