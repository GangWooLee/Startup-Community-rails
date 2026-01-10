# frozen_string_literal: true

module Ai
  module Agents
    module MarketAnalysis
      # 시장 분석 프롬프트 빌더
      #
      # 3가지 모드에 맞는 프롬프트 생성:
      # - Grounding (실시간 웹검색)
      # - Static Tools (정적 데이터)
      # - Direct (도구 없음)
      #
      # 사용 예:
      #   builder = PromptBuilder.new(idea: "...", follow_up_answers: {}, previous_results: {})
      #   builder.system_prompt(:grounding)
      #   builder.user_prompt
      #   builder.user_prompt_with_grounding(search_context)
      class PromptBuilder
        KEY_TRANSLATIONS = {
          "target" => "타겟 사용자",
          "problem" => "해결하려는 문제",
          "differentiator" => "차별화 포인트"
        }.freeze

        attr_reader :idea, :follow_up_answers, :previous_results

        def initialize(idea:, follow_up_answers: {}, previous_results: {})
          @idea = idea
          @follow_up_answers = follow_up_answers || {}
          @previous_results = previous_results || {}
        end

        # ==========================================================================
        # System Prompts
        # ==========================================================================

        def system_prompt(mode = :direct)
          case mode
          when :grounding then system_prompt_with_grounding
          when :static then system_prompt_with_tools
          else system_prompt_direct
          end
        end

        # ==========================================================================
        # User Prompts
        # ==========================================================================

        def user_prompt
          prompt = build_base_context
          prompt += build_previous_results_context
          prompt += "\n\n위 아이디어의 시장 분석을 수행해주세요."
          prompt
        end

        def user_prompt_with_grounding(search_context)
          prompt = user_prompt
          return prompt if search_context.blank?

          prompt += "\n\n## 실시간 웹 검색 결과 (Google Search)"
          prompt += search_context_section(:market_size, "시장 규모 데이터", search_context)
          prompt += search_context_section(:competitors, "경쟁사 정보", search_context)
          prompt += search_context_section(:trends, "트렌드 정보", search_context)
          prompt += "\n\n위 실시간 검색 결과를 바탕으로 시장 분석을 수행해주세요."
          prompt
        end

        private

        # ==========================================================================
        # System Prompt Variants
        # ==========================================================================

        def system_prompt_direct
          <<~PROMPT
            당신은 시장 분석 및 경쟁 전략 전문가입니다.
            스타트업 아이디어의 시장 기회와 경쟁 환경을 분석합니다.

            #{json_response_format}

            규칙:
            - 시장 규모는 가능한 구체적인 수치 포함
            - 경쟁사는 실제 존재하는 서비스명 사용
            - 기회와 리스크를 균형있게 분석
            - 한국 시장 기준으로 분석
            - JSON 외의 다른 텍스트는 출력하지 않음
          PROMPT
        end

        def system_prompt_with_grounding
          <<~PROMPT
            당신은 시장 분석 및 경쟁 전략 전문가입니다.
            스타트업 아이디어의 시장 기회와 경쟁 환경을 분석합니다.

            ## 중요: 실시간 검색 결과 활용

            사용자 메시지에 "실시간 웹 검색 결과"가 포함되어 있습니다.
            이 데이터는 Google Search를 통해 방금 수집된 최신 정보입니다.
            반드시 이 데이터를 우선적으로 활용하여 분석해주세요.

            #{json_response_format}

            규칙:
            - 검색 결과에서 구체적인 수치(시장 규모, 성장률 등)를 추출하여 사용
            - 경쟁사는 검색 결과에서 언급된 실제 서비스명 사용
            - 검색 결과가 불충분한 경우 "추정" 표시
            - 한국 시장 기준으로 분석
            - JSON 외의 다른 텍스트는 출력하지 않음
          PROMPT
        end

        def system_prompt_with_tools
          <<~PROMPT
            당신은 시장 분석 및 경쟁 전략 전문가입니다.
            스타트업 아이디어의 시장 기회와 경쟁 환경을 분석합니다.

            ## 사용 가능한 도구

            분석 시 다음 도구를 활용하여 정확한 데이터를 수집하세요:

            1. **get_market_size**: 산업별 시장 규모와 성장률 조회
            2. **get_market_trends**: 산업별 최신 트렌드 조회
            3. **find_competitors**: 분야별 주요 경쟁사 목록 조회
            4. **get_competitor_info**: 특정 기업 상세 정보 조회

            ## 분석 프로세스

            1. 아이디어의 산업 분야를 파악
            2. get_market_size로 시장 규모 조회
            3. get_market_trends로 트렌드 파악
            4. find_competitors로 경쟁사 목록 확보
            5. 수집된 데이터를 바탕으로 JSON 응답 생성

            #{json_response_format}

            규칙:
            - 도구 조회 결과를 적극 활용하여 구체적인 수치 포함
            - 경쟁사는 도구에서 조회한 실제 서비스명 사용
            - 도구 조회 결과가 없어도 분석을 진행하되, 추정임을 명시
            - 한국 시장 기준으로 분석
            - 최종 응답은 반드시 JSON 형식으로만 출력
          PROMPT
        end

        def json_response_format
          <<~FORMAT
            ## 응답 형식

            반드시 다음 JSON 형식으로만 응답하세요:
            ```json
            {
              "market_analysis": {
                "potential": "높음/중간/낮음 중 하나",
                "market_size": "시장 규모 (예: 국내 XX 시장 규모 약 X조원)",
                "trends": "트렌드 요약 (100자 이내)",
                "competitors": ["경쟁사1", "경쟁사2", "경쟁사3", "경쟁사4", "경쟁사5"],
                "differentiation": "차별화 포인트 (100자 이내)"
              },
              "market_opportunities": ["기회 1", "기회 2", "기회 3"],
              "market_risks": ["리스크 1", "리스크 2", "리스크 3"]
            }
            ```
          FORMAT
        end

        # ==========================================================================
        # Context Builders
        # ==========================================================================

        def build_base_context
          prompt = "## 아이디어\n#{idea}"

          if follow_up_answers.present?
            prompt += "\n\n## 추가 정보"
            follow_up_answers.each do |key, value|
              next if value.blank?
              label = KEY_TRANSLATIONS[key.to_s] || key.to_s.humanize
              prompt += "\n- #{label}: #{value}"
            end
          end

          prompt
        end

        def build_previous_results_context
          prompt = ""
          prompt += build_summary_context
          prompt += build_target_user_context
          prompt
        end

        def build_summary_context
          return "" unless previous_results[:summary].present?

          summary = previous_results[:summary]
          context = "\n\n## 아이디어 요약"
          context += "\n- 핵심 요약: #{summary[:summary]}" if summary[:summary]
          context += "\n- 핵심 가치: #{summary[:core_value]}" if summary[:core_value]
          context += "\n- 문제 정의: #{summary[:problem_statement]}" if summary[:problem_statement]
          context
        end

        def build_target_user_context
          return "" unless previous_results[:target_user].present?

          target = previous_results[:target_user]
          context = "\n\n## 타겟 사용자 분석"

          if target[:target_users].present?
            context += "\n- 주요 타겟: #{target[:target_users][:primary]}"
            if target[:target_users][:characteristics].present?
              context += "\n- 사용자 특성: #{target[:target_users][:characteristics].join(', ')}"
            end
          end

          if target[:user_pain_points].present?
            context += "\n- 사용자 고민: #{target[:user_pain_points].join(', ')}"
          end

          context
        end

        def search_context_section(key, title, search_context)
          return "" unless search_context[key].present?
          "\n\n### #{title}\n#{search_context[key]}"
        end
      end
    end
  end
end
