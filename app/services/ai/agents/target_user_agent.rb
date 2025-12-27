# frozen_string_literal: true

module Ai
  module Agents
    # 타겟 사용자 분석 에이전트
    # 아이디어의 타겟 사용자, 페르소나, 니즈를 분석
    # 이전 에이전트(SummaryAgent)의 결과를 컨텍스트로 활용
    #
    # 입력: idea, follow_up_answers, previous_results[:summary]
    # 출력: { target_users: { primary, characteristics, personas }, user_pain_points, user_goals }
    class TargetUserAgent < BaseAgent
      def initialize(context)
        @idea = context[:idea]
        @follow_up_answers = context[:follow_up_answers] || {}
        @previous_results = context[:previous_results] || {}
        super(llm: LangchainConfig.llm_for_agent(:target_user))
      end

      def analyze
        with_error_handling do
          response = llm.chat(messages: build_messages)
          log_token_usage(response, "TargetUserAgent")

          result = parse_json_response(response.chat_completion)
          validate_result(result)
        end
      end

      def fallback_result
        {
          target_users: {
            primary: "타겟 사용자 분석 필요",
            characteristics: [],
            personas: []
          },
          user_pain_points: [],
          user_goals: []
        }
      end

      private

      def build_messages
        format_messages_for_gemini(
          [{ role: "user", content: user_prompt }],
          system_prompt: system_prompt
        )
      end

      def system_prompt
        <<~PROMPT
          당신은 사용자 리서치 및 페르소나 개발 전문가입니다.
          스타트업 아이디어를 분석하여 타겟 사용자를 깊이 있게 분석합니다.

          반드시 다음 JSON 형식으로만 응답하세요:
          ```json
          {
            "target_users": {
              "primary": "주요 타겟 사용자 정의 (예: 20-30대 직장인)",
              "characteristics": [
                "사용자 특성 1",
                "사용자 특성 2",
                "사용자 특성 3"
              ],
              "personas": [
                {
                  "name": "페르소나 이름 (예: 열정적 대학생 창업가)",
                  "age_range": "나이대 (예: 20-25세)",
                  "description": "페르소나 상세 설명 (100자 이내)"
                },
                {
                  "name": "두 번째 페르소나",
                  "age_range": "나이대",
                  "description": "설명"
                }
              ]
            },
            "user_pain_points": [
              "사용자가 겪는 문제점 1",
              "사용자가 겪는 문제점 2",
              "사용자가 겪는 문제점 3"
            ],
            "user_goals": [
              "사용자의 목표 1",
              "사용자의 목표 2",
              "사용자의 목표 3"
            ]
          }
          ```

          규칙:
          - 페르소나는 반드시 2개 이상 작성
          - 구체적이고 실제적인 사용자 프로필 작성
          - 사용자의 실제 고민과 목표를 반영
          - JSON 외의 다른 텍스트는 출력하지 않음
        PROMPT
      end

      def user_prompt
        prompt = build_base_context

        # 이전 에이전트 결과 활용
        summary_result = @previous_results[:summary]
        if summary_result.present?
          prompt += "\n\n## 아이디어 요약 (이전 분석 결과)"
          prompt += "\n- 핵심 요약: #{summary_result[:summary]}" if summary_result[:summary]
          prompt += "\n- 핵심 가치: #{summary_result[:core_value]}" if summary_result[:core_value]
          prompt += "\n- 문제 정의: #{summary_result[:problem_statement]}" if summary_result[:problem_statement]
        end

        prompt += "\n\n위 아이디어의 타겟 사용자를 분석해주세요."
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
          target_users: validate_target_users(result[:target_users]),
          user_pain_points: result[:user_pain_points] || [],
          user_goals: result[:user_goals] || []
        }
      end

      def validate_target_users(target_users)
        return fallback_result[:target_users] unless target_users.is_a?(Hash)

        {
          primary: target_users[:primary] || fallback_result[:target_users][:primary],
          characteristics: target_users[:characteristics] || [],
          personas: validate_personas(target_users[:personas])
        }
      end

      def validate_personas(personas)
        return [] unless personas.is_a?(Array)

        personas.map do |persona|
          next unless persona.is_a?(Hash)
          {
            name: persona[:name] || "페르소나",
            age_range: persona[:age_range] || "미정",
            description: persona[:description] || ""
          }
        end.compact
      end
    end
  end
end
