# frozen_string_literal: true

module Ai
  module Agents
    # 시장 분석 에이전트
    #
    # 시장 규모, 트렌드, 경쟁사, 차별화 전략을 분석
    # 이전 에이전트들의 결과(요약, 타겟 사용자)를 컨텍스트로 활용
    #
    # Tool 통합 (v3):
    # - 모드 1 (GROUNDING): GeminiGroundingTool - 실시간 Google Search
    # - 모드 2 (STATIC): MarketDataTool, CompetitorDatabaseTool - 정적 데이터
    # - 모드 3 (NONE): 도구 없이 LLM 직접 호출
    #
    # 입력: idea, follow_up_answers, previous_results[:summary, :target_user]
    # 출력: { market_analysis: { potential, market_size, trends, competitors, differentiation },
    #        market_opportunities, market_risks }
    #
    # 리팩토링 v4: 서비스 분리
    # - IndustryExtractor: 산업 분야 추출
    # - GroundingDataGatherer: 실시간 검색 데이터 수집
    # - PromptBuilder: 프롬프트 생성
    # - ResultValidator: 결과 검증
    class MarketAnalysisAgent < BaseAgent
      # 도구 모드: :grounding (실시간 웹검색), :static (정적 데이터), :none (도구 없음)
      TOOL_MODE = :grounding

      def initialize(context)
        @idea = context[:idea]
        @follow_up_answers = context[:follow_up_answers] || {}
        @previous_results = context[:previous_results] || {}
        super(llm: LangchainConfig.llm_for_agent(:market_analysis))
      end

      def analyze
        with_error_handling do
          case TOOL_MODE
          when :grounding
            grounding_available? ? analyze_with_grounding : analyze_without_tools
          when :static
            static_tools_available? ? analyze_with_static_tools : analyze_without_tools
          else
            analyze_without_tools
          end
        end
      end

      def fallback_result
        result_validator.fallback_result
      end

      private

      # ==========================================================================
      # Service Objects
      # ==========================================================================

      def industry_extractor
        @industry_extractor ||= MarketAnalysis::IndustryExtractor.new(
          idea: @idea,
          follow_up_answers: @follow_up_answers
        )
      end

      def prompt_builder
        @prompt_builder ||= MarketAnalysis::PromptBuilder.new(
          idea: @idea,
          follow_up_answers: @follow_up_answers,
          previous_results: @previous_results
        )
      end

      def result_validator
        @result_validator ||= MarketAnalysis::ResultValidator.new
      end

      # ==========================================================================
      # Analysis Strategies
      # ==========================================================================

      def analyze_with_grounding
        Rails.logger.info("[MarketAnalysisAgent] Using Gemini Grounding for real-time web search")

        industry = industry_extractor.extract
        gatherer = MarketAnalysis::GroundingDataGatherer.new(industry: industry)
        search_context = gatherer.gather

        response = llm.chat(messages: build_grounded_messages(search_context))
        log_token_usage(response, "MarketAnalysisAgent (Grounding)")

        result = parse_json_response(response.chat_completion)
        result_validator.validate(result)
      rescue StandardError => e
        Rails.logger.error("[MarketAnalysisAgent] Grounding failed: #{e.message}, falling back to static tools")
        static_tools_available? ? analyze_with_static_tools : analyze_without_tools
      end

      def analyze_with_static_tools
        Rails.logger.info("[MarketAnalysisAgent] Using static tools: MarketDataTool, CompetitorDatabaseTool")

        assistant = Langchain::Assistant.new(
          llm: llm,
          instructions: prompt_builder.system_prompt(:static),
          tools: static_tools
        )

        assistant.add_message(role: "user", content: prompt_builder.user_prompt)
        assistant.run(auto_tool_execution: true)

        log_assistant_usage(assistant)

        final_content = assistant.messages.last&.content
        if final_content.blank?
          Rails.logger.warn("[MarketAnalysisAgent] Empty response from assistant")
          return fallback_result
        end

        result = parse_json_response(final_content)
        result_validator.validate(result)
      rescue StandardError => e
        Rails.logger.error("[MarketAnalysisAgent] Static tool execution failed: #{e.message}, falling back to direct LLM")
        analyze_without_tools
      end

      def analyze_without_tools
        response = llm.chat(messages: build_messages)
        log_token_usage(response, "MarketAnalysisAgent")

        result = parse_json_response(response.chat_completion)
        result_validator.validate(result)
      end

      # ==========================================================================
      # Message Building
      # ==========================================================================

      def build_messages
        format_messages_for_gemini(
          [ { role: "user", content: prompt_builder.user_prompt } ],
          system_prompt: prompt_builder.system_prompt(:direct)
        )
      end

      def build_grounded_messages(search_context)
        format_messages_for_gemini(
          [ { role: "user", content: prompt_builder.user_prompt_with_grounding(search_context) } ],
          system_prompt: prompt_builder.system_prompt(:grounding)
        )
      end

      # ==========================================================================
      # Tool Helpers
      # ==========================================================================

      def static_tools
        [
          Ai::Tools::MarketDataTool.new,
          Ai::Tools::CompetitorDatabaseTool.new
        ]
      end

      def grounding_available?
        defined?(Ai::Tools::GeminiGroundingTool)
      rescue StandardError
        false
      end

      def static_tools_available?
        defined?(Ai::Tools::MarketDataTool) && defined?(Ai::Tools::CompetitorDatabaseTool)
      rescue StandardError
        false
      end

      def log_assistant_usage(assistant)
        Rails.logger.info(
          "[MarketAnalysisAgent] Assistant - Messages: #{assistant.messages.size}, " \
          "Prompt tokens: #{assistant.total_prompt_tokens}, " \
          "Completion tokens: #{assistant.total_completion_tokens}"
        )
      end
    end
  end
end
