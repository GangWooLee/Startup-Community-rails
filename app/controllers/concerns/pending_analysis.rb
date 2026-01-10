# frozen_string_literal: true

# 대기 중인 AI 분석 복원 관련 메서드 (Lazy Registration)
#
# 포함 기능:
# - restore_pending_analysis: 캐시에서 완료된 분석 결과 복원
# - restore_pending_input_and_analyze: 입력만 저장된 경우 비동기 분석 실행
# - mock_analysis_result: LLM 미설정 시 Mock 결과 생성
module PendingAnalysis
  extend ActiveSupport::Concern

  private

  # 대기 중인 AI 분석 결과 복원 (비로그인 상태에서 분석 후 로그인 시)
  # 캐시에 저장된 분석 결과를 DB로 이전하고, 해당 IdeaAnalysis 레코드 반환
  def restore_pending_analysis
    return nil unless logged_in?
    return nil unless session[:pending_analysis_key].present?

    cache_key = session[:pending_analysis_key]
    cached_data = Rails.cache.read(cache_key)

    return nil unless cached_data

    Rails.logger.info "[AI] Restoring pending analysis from cache: #{cache_key}"

    # DB에 저장
    idea_analysis = current_user.idea_analyses.create!(
      idea: cached_data[:idea],
      follow_up_answers: cached_data[:follow_up_answers],
      analysis_result: cached_data[:analysis_result],
      score: cached_data[:score],
      is_real_analysis: cached_data[:is_real_analysis],
      partial_success: cached_data[:partial_success]
    )

    # 정리
    Rails.cache.delete(cache_key)
    session.delete(:pending_analysis_key)

    Rails.logger.info "[AI] Restored analysis as IdeaAnalysis##{idea_analysis.id}"
    idea_analysis
  rescue => e
    Rails.logger.error "[AI] Failed to restore pending analysis: #{e.message}"
    session.delete(:pending_analysis_key)
    nil
  end

  # 대기 중인 입력 데이터 복원 + 비동기 AI 분석 (Lazy Registration)
  # 비로그인 상태에서 입력만 저장 → 로그인 후 백그라운드에서 AI 분석 실행
  def restore_pending_input_and_analyze
    return nil unless logged_in?
    return nil unless session[:pending_input_key].present?

    cache_key = session[:pending_input_key]
    cached_input = Rails.cache.read(cache_key)

    return nil unless cached_input

    # 횟수 제한 확인 (로그인한 사용자의 기존 분석 횟수 체크)
    max_analyses = OnboardingController::MAX_FREE_ANALYSES
    usage_count = current_user.idea_analyses.count

    if usage_count >= max_analyses
      Rails.logger.warn "[AI] User##{current_user.id} exceeded free analysis limit (#{usage_count}/#{max_analyses})"

      # 캐시 및 세션 정리
      Rails.cache.delete(cache_key)
      session.delete(:pending_input_key)

      # 횟수 초과 알림
      flash[:alert] = "AI 분석 무료 이용 횟수(#{max_analyses}회)를 모두 사용했습니다."

      return nil
    end

    Rails.logger.info "[AI] Creating placeholder IdeaAnalysis for async processing: #{cache_key}"

    # 1. placeholder 레코드 생성 (status: analyzing)
    idea_analysis = current_user.idea_analyses.create!(
      idea: cached_input[:idea],
      follow_up_answers: cached_input[:follow_up_answers],
      status: :analyzing,        # 분석 중 상태
      analysis_result: {},       # 빈 결과
      score: nil,
      is_real_analysis: false,
      partial_success: false
    )

    # 2. 캐시 정리
    Rails.cache.delete(cache_key)
    session.delete(:pending_input_key)

    # 3. 백그라운드 잡 실행
    AiAnalysisJob.perform_later(idea_analysis.id)

    Rails.logger.info "[AI] Enqueued AiAnalysisJob for IdeaAnalysis##{idea_analysis.id}"
    idea_analysis
  rescue => e
    Rails.logger.error "[AI] Failed to create async analysis: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    session.delete(:pending_input_key)
    nil
  end

  # Mock 분석 결과 (LLM 미설정 시) - 간략 버전
  def mock_analysis_result(idea)
    {
      summary: "AI 분석 결과입니다.",
      target_users: {
        primary: "타겟 사용자",
        characteristics: [],
        personas: []
      },
      market_analysis: {
        potential: "높음",
        market_size: "분석 중",
        trends: "분석 중",
        competitors: [],
        differentiation: "분석 중"
      },
      recommendations: {
        mvp_features: [],
        challenges: [],
        next_steps: []
      },
      score: {
        overall: 70,
        weak_areas: [],
        strong_areas: [],
        improvement_tips: []
      },
      actions: [],
      required_expertise: {
        roles: [],
        skills: [],
        description: "분석 중"
      },
      analyzed_at: Time.current,
      idea: idea
    }
  end
end
