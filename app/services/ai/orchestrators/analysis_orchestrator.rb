# frozen_string_literal: true

module Ai
  module Orchestrators
    # 아이디어 분석 오케스트레이터
    # 5개 전문 에이전트를 순차 실행하여 종합 분석 결과 생성
    #
    # 실행 순서:
    # 1. SummaryAgent - 아이디어 요약 및 핵심 가치 추출
    # 2. TargetUserAgent - 타겟 사용자 및 페르소나 분석
    # 3. MarketAnalysisAgent - 시장 규모, 경쟁사, 트렌드 분석
    # 4. StrategyAgent - MVP, 도전과제, 액션 아이템 도출
    # 5. ScoringAgent - 종합 점수 및 필요 전문성 평가
    #
    # 사용법:
    #   orchestrator = Ai::Orchestrators::AnalysisOrchestrator.new(idea, follow_up_answers: answers)
    #   result = orchestrator.analyze
    #
    class AnalysisOrchestrator < BaseAgent
      # 에이전트 실행 순서 정의
      AGENT_SEQUENCE = [:summary, :target_user, :market_analysis, :strategy, :scoring].freeze

      # 에이전트 타입 → 클래스 매핑
      AGENT_CLASSES = {
        summary: Agents::SummaryAgent,
        target_user: Agents::TargetUserAgent,
        market_analysis: Agents::MarketAnalysisAgent,
        strategy: Agents::StrategyAgent,
        scoring: Agents::ScoringAgent
      }.freeze

      def initialize(idea, follow_up_answers: {})
        super()
        @idea = idea
        @follow_up_answers = follow_up_answers
        @results = {}
        @errors = []
        @start_time = nil
      end

      # 전체 분석 실행
      def analyze
        @start_time = Time.current

        with_error_handling do
          Rails.logger.info("[AnalysisOrchestrator] Starting multi-agent analysis")

          # 순차 실행: 각 에이전트가 이전 결과를 받음
          AGENT_SEQUENCE.each_with_index do |agent_type, index|
            Rails.logger.info("[AnalysisOrchestrator] Step #{index + 1}/#{AGENT_SEQUENCE.size}: #{agent_type}")
            execute_agent(agent_type)
          end

          merge_results
        end
      end

      private

      # 단일 에이전트 실행
      def execute_agent(agent_type)
        agent = build_agent(agent_type)
        agent_start = Time.current

        result = agent.analyze

        elapsed = (Time.current - agent_start).round(2)
        Rails.logger.info("[AnalysisOrchestrator] #{agent_type} completed in #{elapsed}s")

        if result[:error]
          handle_agent_error(agent_type, result[:message], agent)
        else
          @results[agent_type] = result
        end
      rescue StandardError => e
        Rails.logger.error("[AnalysisOrchestrator] #{agent_type} failed: #{e.message}")
        handle_agent_error(agent_type, e.message, build_agent(agent_type))
      end

      # 에이전트 인스턴스 생성
      def build_agent(type)
        context = {
          idea: @idea,
          follow_up_answers: @follow_up_answers,
          previous_results: @results
        }

        agent_class = AGENT_CLASSES[type]
        raise "Unknown agent type: #{type}" unless agent_class

        agent_class.new(context)
      end

      # 에이전트 오류 처리
      def handle_agent_error(agent_type, error_message, agent)
        @errors << { agent: agent_type, error: error_message, timestamp: Time.current }
        @results[agent_type] = agent.fallback_result
      end

      # 모든 에이전트 결과를 최종 형식으로 병합
      def merge_results
        elapsed_total = @start_time ? (Time.current - @start_time).round(2) : 0

        Rails.logger.info(
          "[AnalysisOrchestrator] Analysis complete. " \
          "Agents: #{AGENT_SEQUENCE.size - @errors.size}/#{AGENT_SEQUENCE.size} succeeded. " \
          "Total time: #{elapsed_total}s"
        )

        {
          # 요약 정보
          summary: @results.dig(:summary, :summary),
          core_value: @results.dig(:summary, :core_value),
          problem_statement: @results.dig(:summary, :problem_statement),

          # 타겟 사용자
          target_users: @results.dig(:target_user, :target_users),
          user_pain_points: @results.dig(:target_user, :user_pain_points),
          user_goals: @results.dig(:target_user, :user_goals),

          # 시장 분석
          market_analysis: @results.dig(:market_analysis, :market_analysis),
          market_opportunities: @results.dig(:market_analysis, :market_opportunities),
          market_risks: @results.dig(:market_analysis, :market_risks),

          # 전략 및 액션
          recommendations: @results.dig(:strategy, :recommendations),
          actions: @results.dig(:strategy, :actions),

          # 점수 및 전문성
          score: @results.dig(:scoring, :score),
          required_expertise: @results.dig(:scoring, :required_expertise),

          # 메타데이터
          analyzed_at: Time.current,
          idea: @idea,
          metadata: build_metadata(elapsed_total)
        }
      end

      # 분석 메타데이터 생성
      def build_metadata(elapsed_total)
        {
          agents_total: AGENT_SEQUENCE.size,
          agents_completed: AGENT_SEQUENCE.size - @errors.size,
          agents_failed: @errors.size,
          agent_errors: @errors,
          partial_success: @errors.any?,
          confidence_level: @results.dig(:scoring, :confidence_level) || "Medium",
          elapsed_seconds: elapsed_total,
          agent_sequence: AGENT_SEQUENCE
        }
      end
    end
  end
end
