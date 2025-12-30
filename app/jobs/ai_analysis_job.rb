# frozen_string_literal: true

# AI 분석 백그라운드 잡
# - 비동기로 AI 분석 실행
# - 분석 완료 시 status 업데이트 → Turbo Stream 브로드캐스트
class AiAnalysisJob < ApplicationJob
  queue_as :default

  def perform(idea_analysis_id)
    idea_analysis = IdeaAnalysis.find(idea_analysis_id)

    # 이미 완료된 경우 스킵
    return if idea_analysis.completed?

    Rails.logger.info "[AiAnalysisJob] Starting analysis for IdeaAnalysis##{idea_analysis_id}"

    begin
      # 단계 완료 콜백 정의 (진행률 브로드캐스트)
      on_stage_complete = ->(stage) { idea_analysis.update_stage!(stage) }

      # AI 분석 실행
      if LangchainConfig.any_llm_configured?
        Rails.logger.info "[AiAnalysisJob] Using real AI analysis with multi-agent orchestrator"

        orchestrator = Ai::Orchestrators::AnalysisOrchestrator.new(
          idea_analysis.idea,
          follow_up_answers: idea_analysis.follow_up_answers || {},
          on_stage_complete: on_stage_complete
        )
        analysis = orchestrator.analyze
        is_real = !analysis[:error]
        partial = analysis.dig(:metadata, :partial_success) || false
      else
        Rails.logger.warn "[AiAnalysisJob] Falling back to mock analysis - no LLM configured"
        # Mock 분석도 단계별 진행률 시뮬레이션
        analysis = mock_analysis_with_progress(idea_analysis.idea, on_stage_complete)
        is_real = false
        partial = false
      end

      # 결과 저장 + 상태 변경 → after_update_commit으로 자동 브로드캐스트
      idea_analysis.update!(
        analysis_result: analysis,
        score: analysis.dig(:score, :overall),
        is_real_analysis: is_real,
        partial_success: partial,
        status: :completed
      )

      Rails.logger.info "[AiAnalysisJob] Completed IdeaAnalysis##{idea_analysis_id}, score: #{idea_analysis.score}"
    rescue StandardError => e
      Rails.logger.error "[AiAnalysisJob] Failed IdeaAnalysis##{idea_analysis_id}: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")

      # 실패 상태로 업데이트 (브로드캐스트 트리거)
      idea_analysis.update!(status: :failed)
    end
  end

  private

  # Mock 분석 결과 + 진행률 시뮬레이션 (LLM 미설정 시)
  def mock_analysis_with_progress(idea, on_stage_complete)
    # 5단계 진행률 시뮬레이션 (각 0.5초)
    (1..5).each do |stage|
      on_stage_complete.call(stage)
      sleep(0.5)
    end

    mock_analysis_result(idea)
  end

  # Mock 분석 결과 (LLM 미설정 시)
  def mock_analysis_result(idea)
    {
      summary: "AI 분석이 완료되었습니다.",
      target_users: {
        primary: "20-30대 초기 창업자 및 예비 창업자",
        characteristics: [ "IT/스타트업에 관심 있는 대학생", "사이드프로젝트를 찾는 개발자/디자이너" ],
        personas: [
          {
            name: "열정적 대학생 창업가",
            age_range: "20-25세",
            description: "IT 관련 학과를 전공하며 창업에 관심이 많은 대학생."
          }
        ]
      },
      market_analysis: {
        potential: "높음",
        market_size: "분석 중",
        trends: "AI 기반 서비스 성장세",
        competitors: [],
        differentiation: "커뮤니티 기반 신뢰 플랫폼"
      },
      recommendations: {
        mvp_features: [
          "핵심 기능 1",
          "핵심 기능 2",
          "핵심 기능 3"
        ],
        challenges: [
          "초기 사용자 확보 → 타겟 마케팅 권장"
        ],
        next_steps: [
          "베타 테스트 진행",
          "피드백 기반 개선"
        ]
      },
      score: {
        overall: 70,
        weak_areas: [ "시장 분석" ],
        strong_areas: [ "아이디어 독창성" ],
        improvement_tips: [
          "타겟 시장의 규모를 구체화하세요"
        ]
      },
      actions: [
        { title: "타깃 정의", description: "명확한 페르소나 설정" },
        { title: "경쟁 분석", description: "유사 서비스 5개 이상 조사" }
      ],
      required_expertise: {
        roles: [ "Developer", "Designer" ],
        skills: [ "React", "UI/UX" ],
        description: "풀스택 개발자와 UI/UX 디자이너 필요"
      },
      analyzed_at: Time.current,
      idea: idea
    }
  end
end
