# frozen_string_literal: true

module Ai
  module Agents
    # 전략 에이전트
    # MVP 기능, 도전과제, 다음 단계, 액션 아이템을 도출
    # 이전 에이전트들의 모든 결과를 종합하여 전략 제시
    #
    # 입력: idea, follow_up_answers, previous_results[:summary, :target_user, :market_analysis]
    # 출력: { recommendations: { mvp_features, challenges, next_steps }, actions }
    class StrategyAgent < BaseAgent
      def initialize(context)
        @idea = context[:idea]
        @follow_up_answers = context[:follow_up_answers] || {}
        @previous_results = context[:previous_results] || {}
        super(llm: LangchainConfig.llm_for_agent(:strategy))
      end

      def analyze
        with_error_handling do
          response = llm.chat(messages: build_messages)
          log_token_usage(response, "StrategyAgent")

          result = parse_json_response(response.chat_completion)
          validate_result(result)
        end
      end

      def fallback_result
        {
          recommendations: {
            mvp_features: [ "MVP 기능 정의 필요" ],
            challenges: [ "도전 과제 분석 필요" ],
            next_steps: [ "다음 단계 계획 필요" ]
          },
          actions: [
            { title: "핵심 타깃 정의", description: "타겟 사용자를 구체화하세요" },
            { title: "MVP 범위 설정", description: "핵심 기능을 정의하세요" },
            { title: "경쟁사 분석", description: "경쟁 환경을 파악하세요" }
          ]
        }
      end

      private

      def build_messages
        format_messages_for_gemini(
          [ { role: "user", content: user_prompt } ],
          system_prompt: system_prompt
        )
      end

      def system_prompt
        <<~PROMPT
          당신은 스타트업 전략 및 제품 기획 전문가입니다.
          아이디어 분석 결과를 바탕으로 실행 가능한 전략을 수립합니다.

          반드시 다음 JSON 형식으로만 응답하세요:
          ```json
          {
            "recommendations": {
              "mvp_features": [
                "MVP 필수 기능 1 (구체적으로 작성)",
                "MVP 필수 기능 2",
                "MVP 필수 기능 3"
              ],
              "challenges": [
                "예상 도전과제 1 → 대응 방안",
                "예상 도전과제 2 → 대응 방안",
                "예상 도전과제 3 → 대응 방안"
              ],
              "next_steps": [
                "다음 단계 1",
                "다음 단계 2",
                "다음 단계 3",
                "다음 단계 4",
                "다음 단계 5"
              ]
            },
            "actions": [
              {
                "title": "액션 제목 (10자 이내)",
                "description": "액션 상세 설명 (50자 이내)"
              },
              {
                "title": "두 번째 액션",
                "description": "설명"
              },
              {
                "title": "세 번째 액션",
                "description": "설명"
              }
            ]
          }
          ```

          규칙:
          - MVP 기능은 반드시 3-5개, 우선순위가 높은 것부터 나열
          - 도전과제는 구체적인 대응 방안과 함께 제시
          - 다음 단계는 실행 가능한 구체적인 액션으로 작성
          - actions는 반드시 3개, 첫 번째가 가장 중요한 액션
          - JSON 외의 다른 텍스트는 출력하지 않음
        PROMPT
      end

      def user_prompt
        prompt = build_base_context
        prompt += build_previous_results_context
        prompt += "\n\n위 분석 결과를 바탕으로 실행 전략과 액션 아이템을 도출해주세요."
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

      def build_previous_results_context
        prompt = ""

        # 요약 결과
        if @previous_results[:summary].present?
          summary = @previous_results[:summary]
          prompt += "\n\n## 아이디어 요약"
          prompt += "\n- 핵심 요약: #{summary[:summary]}" if summary[:summary]
          prompt += "\n- 핵심 가치: #{summary[:core_value]}" if summary[:core_value]
          prompt += "\n- 문제 정의: #{summary[:problem_statement]}" if summary[:problem_statement]
        end

        # 타겟 사용자 결과
        if @previous_results[:target_user].present?
          target = @previous_results[:target_user]
          prompt += "\n\n## 타겟 사용자"
          if target[:target_users].present?
            prompt += "\n- 주요 타겟: #{target[:target_users][:primary]}"
          end
          if target[:user_pain_points].present?
            prompt += "\n- 사용자 고민: #{target[:user_pain_points].join(', ')}"
          end
          if target[:user_goals].present?
            prompt += "\n- 사용자 목표: #{target[:user_goals].join(', ')}"
          end
        end

        # 시장 분석 결과
        if @previous_results[:market_analysis].present?
          market = @previous_results[:market_analysis]
          prompt += "\n\n## 시장 분석"
          if market[:market_analysis].present?
            ma = market[:market_analysis]
            prompt += "\n- 시장 잠재력: #{ma[:potential]}" if ma[:potential]
            prompt += "\n- 시장 규모: #{ma[:market_size]}" if ma[:market_size]
            prompt += "\n- 경쟁사: #{ma[:competitors].join(', ')}" if ma[:competitors].present?
            prompt += "\n- 차별화: #{ma[:differentiation]}" if ma[:differentiation]
          end
          if market[:market_risks].present?
            prompt += "\n- 시장 리스크: #{market[:market_risks].join(', ')}"
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
          recommendations: validate_recommendations(result[:recommendations]),
          actions: validate_actions(result[:actions])
        }
      end

      def validate_recommendations(recommendations)
        return fallback_result[:recommendations] unless recommendations.is_a?(Hash)

        {
          mvp_features: recommendations[:mvp_features] || fallback_result[:recommendations][:mvp_features],
          challenges: recommendations[:challenges] || fallback_result[:recommendations][:challenges],
          next_steps: recommendations[:next_steps] || fallback_result[:recommendations][:next_steps]
        }
      end

      def validate_actions(actions)
        return fallback_result[:actions] unless actions.is_a?(Array)

        validated = actions.map do |action|
          next unless action.is_a?(Hash)
          {
            title: action[:title] || "액션",
            description: action[:description] || ""
          }
        end.compact

        validated.empty? ? fallback_result[:actions] : validated
      end
    end
  end
end
