# frozen_string_literal: true

module Ai
  module Agents
    # 시장 분석 에이전트
    # 시장 규모, 트렌드, 경쟁사, 차별화 전략을 분석
    # 이전 에이전트들의 결과(요약, 타겟 사용자)를 컨텍스트로 활용
    #
    # Tool 통합 (v3):
    # - 모드 1 (GROUNDING): GeminiGroundingTool - 실시간 Google Search
    # - 모드 2 (STATIC): MarketDataTool, CompetitorDatabaseTool - 정적 데이터
    # - 모드 3 (NONE): 도구 없이 LLM 직접 호출
    #
    # 입력: idea, follow_up_answers, previous_results[:summary, :target_user]
    # 출력: { market_analysis: { potential, market_size, trends, competitors, differentiation }, market_opportunities, market_risks }
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

      private

      # 실시간 웹 검색 분석 (Gemini Grounding)
      def analyze_with_grounding
        Rails.logger.info("[MarketAnalysisAgent] Using Gemini Grounding for real-time web search")

        # 먼저 실시간 검색으로 최신 데이터 수집
        grounding_tool = Ai::Tools::GeminiGroundingTool.new
        search_context = gather_grounding_data(grounding_tool)

        # 수집된 데이터를 컨텍스트로 LLM에 전달
        response = llm.chat(messages: build_grounded_messages(search_context))
        log_token_usage(response, "MarketAnalysisAgent (Grounding)")

        result = parse_json_response(response.chat_completion)
        validate_result(result)
      rescue StandardError => e
        Rails.logger.error("[MarketAnalysisAgent] Grounding failed: #{e.message}, falling back to static tools")
        static_tools_available? ? analyze_with_static_tools : analyze_without_tools
      end

      # 실시간 검색 데이터 수집
      def gather_grounding_data(grounding_tool)
        industry = extract_industry_from_idea
        Rails.logger.info("[MarketAnalysisAgent] Gathering grounding data for: #{industry}")

        results = {}

        # 시장 규모 검색
        begin
          market_result = grounding_tool.search_market_data(query: "한국 #{industry} 시장 규모")
          results[:market_size] = market_result.content if market_result&.content.present?
        rescue => e
          Rails.logger.warn("[MarketAnalysisAgent] Market size search failed: #{e.message}")
        end

        # 경쟁사 검색
        begin
          competitor_result = grounding_tool.search_competitors(query: "한국 #{industry} 주요 기업 스타트업")
          results[:competitors] = competitor_result.content if competitor_result&.content.present?
        rescue => e
          Rails.logger.warn("[MarketAnalysisAgent] Competitor search failed: #{e.message}")
        end

        # 트렌드 검색
        begin
          trend_result = grounding_tool.search_trends(query: "#{industry} 트렌드 전망")
          results[:trends] = trend_result.content if trend_result&.content.present?
        rescue => e
          Rails.logger.warn("[MarketAnalysisAgent] Trend search failed: #{e.message}")
        end

        results
      end

      # 아이디어에서 산업 분야 추출
      def extract_industry_from_idea
        # 간단한 키워드 매칭으로 산업 추출
        idea_text = "#{@idea} #{@follow_up_answers.values.join(' ')}"

        industry_keywords = {
          "이커머스" => %w[쇼핑 커머스 판매 마켓 온라인스토어],
          "핀테크" => %w[금융 결제 투자 송금 뱅킹 보험],
          "에듀테크" => %w[교육 학습 강의 튜터 온라인교육],
          "헬스테크" => %w[건강 의료 헬스케어 병원 진료],
          "푸드테크" => %w[음식 배달 식품 레스토랑 밀키트],
          "모빌리티" => %w[이동 차량 배차 택시 킥보드],
          "프롭테크" => %w[부동산 집 매물 임대 전세],
          "HR테크" => %w[채용 인사 HR 구인 구직],
          "SaaS" => %w[소프트웨어 서비스 B2B 기업용],
          "AI" => %w[인공지능 AI 머신러닝 자동화],
          "커뮤니티" => %w[커뮤니티 네트워킹 소셜 플랫폼],
          "외주" => %w[외주 프리랜서 개발자 디자이너 매칭]
        }

        industry_keywords.each do |industry, keywords|
          return industry if keywords.any? { |kw| idea_text.include?(kw) }
        end

        "스타트업" # 기본값
      end

      # 정적 도구 분석 (Langchain::Assistant 사용)
      def analyze_with_static_tools
        Rails.logger.info("[MarketAnalysisAgent] Using static tools: MarketDataTool, CompetitorDatabaseTool")

        assistant = Langchain::Assistant.new(
          llm: llm,
          instructions: system_prompt_with_tools,
          tools: static_tools
        )

        assistant.add_message(role: "user", content: user_prompt)
        assistant.run(auto_tool_execution: true)

        # 토큰 사용량 로깅
        log_assistant_usage(assistant)

        # 마지막 메시지에서 결과 추출
        final_content = assistant.messages.last&.content
        if final_content.blank?
          Rails.logger.warn("[MarketAnalysisAgent] Empty response from assistant")
          return fallback_result
        end

        result = parse_json_response(final_content)
        validate_result(result)
      rescue StandardError => e
        Rails.logger.error("[MarketAnalysisAgent] Static tool execution failed: #{e.message}, falling back to direct LLM")
        analyze_without_tools
      end

      # 기존 방식 (도구 없이 직접 LLM 호출)
      def analyze_without_tools
        response = llm.chat(messages: build_messages)
        log_token_usage(response, "MarketAnalysisAgent")

        result = parse_json_response(response.chat_completion)
        validate_result(result)
      end

      # 정적 도구 목록
      def static_tools
        [
          Ai::Tools::MarketDataTool.new,
          Ai::Tools::CompetitorDatabaseTool.new
        ]
      end

      # Grounding 사용 가능 여부 확인
      def grounding_available?
        defined?(Ai::Tools::GeminiGroundingTool)
      rescue StandardError
        false
      end

      # 정적 도구 클래스 로드 가능 여부 확인
      def static_tools_available?
        defined?(Ai::Tools::MarketDataTool) && defined?(Ai::Tools::CompetitorDatabaseTool)
      rescue StandardError
        false
      end

      # Assistant 토큰 사용량 로깅
      def log_assistant_usage(assistant)
        Rails.logger.info(
          "[MarketAnalysisAgent] Assistant - Messages: #{assistant.messages.size}, " \
          "Prompt tokens: #{assistant.total_prompt_tokens}, " \
          "Completion tokens: #{assistant.total_completion_tokens}"
        )
      end

      public

      def fallback_result
        {
          market_analysis: {
            potential: "분석 필요",
            market_size: "시장 규모 조사 필요",
            trends: "트렌드 분석 필요",
            competitors: [],
            differentiation: "차별화 전략 필요"
          },
          market_opportunities: [],
          market_risks: []
        }
      end

      private

      def build_messages
        format_messages_for_gemini(
          [{ role: "user", content: user_prompt }],
          system_prompt: system_prompt
        )
      end

      # Grounding 검색 결과를 포함한 메시지 빌드
      def build_grounded_messages(search_context)
        format_messages_for_gemini(
          [{ role: "user", content: user_prompt_with_grounding(search_context) }],
          system_prompt: system_prompt_with_grounding
        )
      end

      # Grounding 검색 결과를 포함한 사용자 프롬프트
      def user_prompt_with_grounding(search_context)
        prompt = user_prompt

        if search_context.present?
          prompt += "\n\n## 실시간 웹 검색 결과 (Google Search)"

          if search_context[:market_size].present?
            prompt += "\n\n### 시장 규모 데이터\n#{search_context[:market_size]}"
          end

          if search_context[:competitors].present?
            prompt += "\n\n### 경쟁사 정보\n#{search_context[:competitors]}"
          end

          if search_context[:trends].present?
            prompt += "\n\n### 트렌드 정보\n#{search_context[:trends]}"
          end

          prompt += "\n\n위 실시간 검색 결과를 바탕으로 시장 분석을 수행해주세요."
        end

        prompt
      end

      # Grounding 모드 시스템 프롬프트
      def system_prompt_with_grounding
        <<~PROMPT
          당신은 시장 분석 및 경쟁 전략 전문가입니다.
          스타트업 아이디어의 시장 기회와 경쟁 환경을 분석합니다.

          ## 중요: 실시간 검색 결과 활용

          사용자 메시지에 "실시간 웹 검색 결과"가 포함되어 있습니다.
          이 데이터는 Google Search를 통해 방금 수집된 최신 정보입니다.
          반드시 이 데이터를 우선적으로 활용하여 분석해주세요.

          ## 응답 형식

          반드시 다음 JSON 형식으로만 응답하세요:
          ```json
          {
            "market_analysis": {
              "potential": "높음/중간/낮음 중 하나",
              "market_size": "시장 규모 (검색 결과의 구체적인 수치 활용)",
              "trends": "트렌드 요약 (검색 결과 기반, 100자 이내)",
              "competitors": ["경쟁사1", "경쟁사2", "경쟁사3", "경쟁사4", "경쟁사5"],
              "differentiation": "이 아이디어의 차별화 포인트 (100자 이내)"
            },
            "market_opportunities": [
              "시장 기회 1",
              "시장 기회 2",
              "시장 기회 3"
            ],
            "market_risks": [
              "시장 리스크 1",
              "시장 리스크 2",
              "시장 리스크 3"
            ]
          }
          ```

          규칙:
          - 검색 결과에서 구체적인 수치(시장 규모, 성장률 등)를 추출하여 사용
          - 경쟁사는 검색 결과에서 언급된 실제 서비스명 사용
          - 검색 결과가 불충분한 경우 "추정" 표시
          - 한국 시장 기준으로 분석
          - JSON 외의 다른 텍스트는 출력하지 않음
        PROMPT
      end

      # 정적 도구 사용 시 시스템 프롬프트
      def system_prompt_with_tools
        <<~PROMPT
          당신은 시장 분석 및 경쟁 전략 전문가입니다.
          스타트업 아이디어의 시장 기회와 경쟁 환경을 분석합니다.

          ## 사용 가능한 도구

          분석 시 다음 도구를 활용하여 정확한 데이터를 수집하세요:

          1. **get_market_size**: 산업별 시장 규모와 성장률 조회
             - 예: get_market_size(industry: "이커머스")

          2. **get_market_trends**: 산업별 최신 트렌드 조회
             - 예: get_market_trends(industry: "에듀테크")

          3. **find_competitors**: 분야별 주요 경쟁사 목록 조회
             - 예: find_competitors(category: "핀테크")

          4. **get_competitor_info**: 특정 기업 상세 정보 조회
             - 예: get_competitor_info(name: "토스")

          ## 분석 프로세스

          1. 아이디어의 산업 분야를 파악
          2. get_market_size로 시장 규모 조회
          3. get_market_trends로 트렌드 파악
          4. find_competitors로 경쟁사 목록 확보
          5. 필요 시 get_competitor_info로 주요 경쟁사 상세 조회
          6. 수집된 데이터를 바탕으로 JSON 응답 생성

          ## 응답 형식

          모든 분석이 완료되면 반드시 다음 JSON 형식으로 응답하세요:
          ```json
          {
            "market_analysis": {
              "potential": "높음/중간/낮음 중 하나",
              "market_size": "시장 규모 (도구 조회 결과 활용)",
              "trends": "트렌드 요약 (100자 이내)",
              "competitors": ["경쟁사1", "경쟁사2", "경쟁사3", "경쟁사4", "경쟁사5"],
              "differentiation": "차별화 포인트 (100자 이내)"
            },
            "market_opportunities": [
              "기회 1",
              "기회 2",
              "기회 3"
            ],
            "market_risks": [
              "리스크 1",
              "리스크 2",
              "리스크 3"
            ]
          }
          ```

          규칙:
          - 도구 조회 결과를 적극 활용하여 구체적인 수치 포함
          - 경쟁사는 도구에서 조회한 실제 서비스명 사용
          - 도구 조회 결과가 없어도 분석을 진행하되, 추정임을 명시
          - 한국 시장 기준으로 분석
          - 최종 응답은 반드시 JSON 형식으로만 출력
        PROMPT
      end

      # 기존 방식 시스템 프롬프트 (도구 없음)
      def system_prompt
        <<~PROMPT
          당신은 시장 분석 및 경쟁 전략 전문가입니다.
          스타트업 아이디어의 시장 기회와 경쟁 환경을 분석합니다.

          반드시 다음 JSON 형식으로만 응답하세요:
          ```json
          {
            "market_analysis": {
              "potential": "높음/중간/낮음 중 하나",
              "market_size": "시장 규모 추정 (예: 국내 XX 시장 규모 약 X조원, 연평균 X% 성장)",
              "trends": "관련 시장 트렌드 및 동향 (100자 이내)",
              "competitors": ["경쟁사1", "경쟁사2", "경쟁사3", "경쟁사4", "경쟁사5"],
              "differentiation": "이 아이디어의 차별화 포인트 (100자 이내)"
            },
            "market_opportunities": [
              "시장 기회 1",
              "시장 기회 2",
              "시장 기회 3"
            ],
            "market_risks": [
              "시장 리스크 1",
              "시장 리스크 2",
              "시장 리스크 3"
            ]
          }
          ```

          규칙:
          - 시장 규모는 가능한 구체적인 수치 포함
          - 경쟁사는 실제 존재하는 서비스명 사용
          - 기회와 리스크를 균형있게 분석
          - 한국 시장 기준으로 분석
          - JSON 외의 다른 텍스트는 출력하지 않음
        PROMPT
      end

      def user_prompt
        prompt = build_base_context

        # 이전 에이전트 결과 활용
        if @previous_results[:summary].present?
          summary = @previous_results[:summary]
          prompt += "\n\n## 아이디어 요약"
          prompt += "\n- 핵심 요약: #{summary[:summary]}" if summary[:summary]
          prompt += "\n- 핵심 가치: #{summary[:core_value]}" if summary[:core_value]
          prompt += "\n- 문제 정의: #{summary[:problem_statement]}" if summary[:problem_statement]
        end

        if @previous_results[:target_user].present?
          target = @previous_results[:target_user]
          prompt += "\n\n## 타겟 사용자 분석"
          if target[:target_users].present?
            prompt += "\n- 주요 타겟: #{target[:target_users][:primary]}"
            if target[:target_users][:characteristics].present?
              prompt += "\n- 사용자 특성: #{target[:target_users][:characteristics].join(', ')}"
            end
          end
          if target[:user_pain_points].present?
            prompt += "\n- 사용자 고민: #{target[:user_pain_points].join(', ')}"
          end
        end

        prompt += "\n\n위 아이디어의 시장 분석을 수행해주세요."
        prompt
      end

      def build_base_context
        prompt = "## 아이디어\n#{@idea}"

        if @follow_up_answers.present?
          prompt += "\n\n## 추가 정보"
          @follow_up_answers.each do |key, value|
            next if value.blank?
            label = translate_key(key)
            prompt += "\n- #{label}: #{value}"
          end
        end

        prompt
      end

      def translate_key(key)
        case key.to_s
        when "target" then "타겟 사용자"
        when "problem" then "해결하려는 문제"
        when "differentiator" then "차별화 포인트"
        else key.to_s.humanize
        end
      end

      def validate_result(result)
        return fallback_result if result[:error] || result[:raw_response]

        {
          market_analysis: validate_market_analysis(result[:market_analysis]),
          market_opportunities: result[:market_opportunities] || [],
          market_risks: result[:market_risks] || []
        }
      end

      def validate_market_analysis(market_analysis)
        return fallback_result[:market_analysis] unless market_analysis.is_a?(Hash)

        {
          potential: market_analysis[:potential] || "분석 필요",
          market_size: market_analysis[:market_size] || fallback_result[:market_analysis][:market_size],
          trends: market_analysis[:trends] || fallback_result[:market_analysis][:trends],
          competitors: market_analysis[:competitors] || [],
          differentiation: market_analysis[:differentiation] || fallback_result[:market_analysis][:differentiation]
        }
      end
    end
  end
end
