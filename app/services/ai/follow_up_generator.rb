# frozen_string_literal: true

module Ai
  # 아이디어 입력 후 추가 질문을 생성하는 AI 서비스
  # 맥락에 따라 2-3개의 구조화된 질문을 동적으로 생성
  class FollowUpGenerator < BaseAgent
    SYSTEM_PROMPT = <<~PROMPT
      당신은 스타트업 아이디어 분석을 위한 인터뷰어입니다.
      사용자가 입력한 아이디어를 바탕으로, 더 정확한 분석을 위해 필요한 추가 질문 2-3개를 생성해주세요.

      ## 질문 생성 원칙
      1. 아이디어에서 명확하지 않은 부분을 파악하는 질문
      2. 구체적이고 답변하기 쉬운 질문 (open-ended 지양)
      3. 타겟 사용자, 해결하려는 문제, 차별화 포인트 중심
      4. 각 질문에 사용자가 클릭해서 선택할 수 있는 예시 2-3개 제공

      ## 출력 형식 (JSON)
      반드시 아래 형식의 JSON으로만 응답하세요:
      ```json
      {
        "questions": [
          {
            "id": "target",
            "question": "주요 타겟 사용자는 누구인가요?",
            "placeholder": "타겟 사용자를 입력해주세요",
            "examples": ["20-30대 직장인", "대학생", "1인 가구"],
            "required": true
          },
          {
            "id": "problem",
            "question": "해결하려는 가장 큰 문제는 무엇인가요?",
            "placeholder": "현재 겪고 있는 불편함을 입력해주세요",
            "examples": ["시간 부족", "비용 문제", "정보 부족"],
            "required": true
          },
          {
            "id": "differentiator",
            "question": "기존 솔루션과 다른 점은 무엇인가요?",
            "placeholder": "차별화 포인트를 입력해주세요",
            "examples": ["AI 자동화", "저렴한 가격", "간편한 사용"],
            "required": false
          }
        ]
      }
      ```

      ## 주의사항
      - 질문은 2개(필수) + 1개(선택) = 총 2-3개
      - 아이디어에서 이미 언급된 내용은 질문하지 않음
      - 한국어로 친근하게 질문
      - 각 질문의 id는 고유해야 함
      - examples는 아이디어와 관련된 구체적이고 짧은 예시 2-3개 (버튼으로 표시됨)

      ## examples 생성 규칙 (중요!)
      - examples는 실제로 유의미한 구체적 답변 예시여야 함
      - 아이디어에 맞는 맞춤형 예시 생성 (예: 음식 배달 앱이면 "직장인 점심", "야식 주문" 등)
      - 절대 금지 예시: "직접 입력", "기타", "없음", "해당 없음", "모름", "선택 안함"
      - 메타적인 선택지(사용자가 직접 하는 행동)가 아닌, 실제 콘텐츠 답변이어야 함
    PROMPT

    def initialize(idea)
      super()
      @idea = idea
    end

    def generate
      with_error_handling do
        response = call_llm
        questions = parse_json_response(response)
        validate_and_normalize(questions)
      end
    end

    private

    def call_llm
      messages = build_chat_messages

      if using_gemini?
        # Gemini API 호출
        formatted = format_messages_for_gemini(messages, system_prompt: SYSTEM_PROMPT)
        response = llm.chat(messages: formatted)
        log_token_usage(response, "FollowUpGenerator")
        response.chat_completion
      else
        # OpenAI API 호출
        response = llm.chat(
          messages: [ { role: "system", content: SYSTEM_PROMPT } ] + messages
        )
        log_token_usage(response, "FollowUpGenerator")
        response.chat_completion
      end
    end

    def build_chat_messages
      [
        {
          role: "user",
          content: <<~MSG
            다음 스타트업 아이디어에 대해 더 정확한 분석을 위한 추가 질문을 생성해주세요:

            === 아이디어 ===
            #{@idea}
            ===============

            이 아이디어에서 명확하지 않은 부분을 파악하고, 분석에 필요한 추가 정보를 얻기 위한 질문 2-3개를 JSON 형식으로 생성해주세요.
          MSG
        }
      ]
    end

    def validate_and_normalize(result)
      return fallback_questions if result[:raw_response] || result[:error]

      questions = result[:questions] || []
      return fallback_questions if questions.empty?

      # 각 질문 정규화
      normalized = questions.map.with_index do |q, i|
        {
          id: q[:id] || "question_#{i + 1}",
          question: q[:question] || "추가 정보를 알려주세요",
          placeholder: q[:placeholder] || "",
          examples: normalize_examples(q[:examples]),
          required: q[:required] != false # 기본값 true
        }
      end

      { questions: normalized.take(3) } # 최대 3개
    end

    # 예시 배열 정규화 (2-3개로 제한, 문자열만 허용)
    def normalize_examples(examples)
      return [] unless examples.is_a?(Array)

      examples.map(&:to_s).reject(&:blank?).take(3)
    end

    def fallback_questions
      {
        questions: [
          {
            id: "target",
            question: "주요 타겟 사용자는 누구인가요?",
            placeholder: "타겟 사용자를 입력해주세요",
            examples: [ "20-30대 직장인", "대학생", "1인 가구" ],
            required: true
          },
          {
            id: "problem",
            question: "해결하려는 가장 큰 문제는 무엇인가요?",
            placeholder: "현재 겪고 있는 불편함을 입력해주세요",
            examples: [ "시간 부족", "비용 문제", "정보 접근성" ],
            required: true
          },
          {
            id: "differentiator",
            question: "기존 서비스와 다른 점은 무엇인가요? (선택)",
            placeholder: "차별화 포인트를 입력해주세요",
            examples: [ "AI 자동화", "커뮤니티 기반", "저렴한 가격" ],
            required: false
          }
        ]
      }
    end
  end
end
