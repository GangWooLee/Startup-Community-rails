# frozen_string_literal: true

module Ai
  module Agents
    # 아이디어 요약 에이전트
    # 입력된 아이디어의 핵심 가치와 문제 정의를 빠르게 추출
    # 저비용 모델(gemini-2.0-flash-lite) 사용으로 비용 최적화
    #
    # 입력: idea, follow_up_answers
    # 출력: { summary, core_value, problem_statement }
    class SummaryAgent < BaseAgent
      def initialize(context)
        @idea = context[:idea]
        @follow_up_answers = context[:follow_up_answers] || {}
        super(llm: LangchainConfig.llm_for_agent(:summary))
      end

      def analyze
        with_error_handling do
          response = llm.chat(messages: build_messages)
          log_token_usage(response, "SummaryAgent")

          result = parse_json_response(response.chat_completion)
          validate_result(result)
        end
      end

      def fallback_result
        {
          summary: "아이디어 분석 요약 생성 중 오류 발생",
          core_value: "핵심 가치 분석 필요",
          problem_statement: "해결하려는 문제 정의 필요"
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
          당신은 스타트업 아이디어 분석 전문가입니다.
          사용자의 아이디어를 읽고 핵심 내용을 간결하게 요약합니다.

          반드시 다음 JSON 형식으로만 응답하세요:
          ```json
          {
            "summary": "아이디어의 한 줄 요약 (30자 이내)",
            "core_value": "이 아이디어가 제공하는 핵심 가치 (50자 이내)",
            "problem_statement": "해결하려는 문제 정의 (100자 이내)"
          }
          ```

          규칙:
          - 간결하고 명확하게 작성
          - 전문 용어보다 쉬운 표현 사용
          - JSON 외의 다른 텍스트는 출력하지 않음
        PROMPT
      end

      def user_prompt
        prompt = "아이디어: #{@idea}"

        if @follow_up_answers.present?
          prompt += "\n\n추가 정보:"
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
          summary: result[:summary] || fallback_result[:summary],
          core_value: result[:core_value] || fallback_result[:core_value],
          problem_statement: result[:problem_statement] || fallback_result[:problem_statement]
        }
      end
    end
  end
end
