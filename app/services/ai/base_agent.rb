# frozen_string_literal: true

module Ai
  # 모든 AI Agent의 기본 클래스
  # 공통 기능: LLM 초기화, 에러 핸들링, 로깅
  class BaseAgent
    attr_reader :llm, :tools

    def initialize(llm: nil, tools: [])
      @llm = llm || default_llm
      @tools = tools
    end

    protected

    # 기본 LLM 인스턴스 가져오기
    def default_llm
      LangchainConfig.default_llm
    end

    # Assistant 생성 (with tools)
    def create_assistant(instructions:)
      Langchain::Assistant.new(
        llm: llm,
        tools: tools,
        instructions: instructions
      )
    end

    # 에러 핸들링 래퍼
    def with_error_handling
      yield
    rescue Langchain::LLM::ApiError => e
      Rails.logger.error("[AI Agent] API Error: #{e.message}")
      { error: true, message: "AI 서비스 오류가 발생했습니다. 잠시 후 다시 시도해주세요." }
    rescue StandardError => e
      Rails.logger.error("[AI Agent] Error: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      { error: true, message: "예기치 않은 오류가 발생했습니다." }
    end

    # 응답을 구조화된 Hash로 파싱
    def parse_json_response(response_text)
      # JSON 블록 추출 (```json ... ``` 형태 처리)
      json_match = response_text.match(/```json\s*(.*?)\s*```/m)
      json_str = json_match ? json_match[1] : response_text

      JSON.parse(json_str, symbolize_names: true)
    rescue JSON::ParserError => e
      Rails.logger.warn("[AI Agent] JSON Parse Error: #{e.message}")
      { raw_response: response_text }
    end

    # 토큰 사용량 로깅
    def log_usage(user:, action:, tokens: nil)
      Rails.logger.info("[AI Agent] User: #{user&.id}, Action: #{action}, Tokens: #{tokens || 'N/A'}")
    end

    # Gemini API 형식에 맞게 메시지 변환
    # OpenAI 형식: { role: "user", content: "hello" }
    # Gemini 형식: { role: "user", parts: [{ text: "hello" }] }
    def format_messages_for_gemini(messages, system_prompt: nil)
      formatted = messages.map do |msg|
        content = msg[:content] || msg["content"]
        role = msg[:role] || msg["role"]

        # system 역할은 Gemini에서 지원하지 않으므로 user로 변환
        role = "user" if role == "system"

        { role: role, parts: [ { text: content } ] }
      end

      # system_prompt가 있으면 맨 앞에 추가
      if system_prompt.present?
        formatted.unshift({ role: "user", parts: [ { text: system_prompt } ] })
        # Gemini는 user/model 교대로 와야 하므로 빈 model 응답 추가
        formatted.insert(1, { role: "model", parts: [ { text: "네, 알겠습니다. 지시에 따르겠습니다." } ] })
      end

      formatted
    end

    # LLM 제공자 확인
    def using_gemini?
      llm.is_a?(Langchain::LLM::GoogleGemini)
    end

    # 응답에서 토큰 사용량 로깅
    def log_token_usage(response, action_name)
      if response.respond_to?(:prompt_tokens) && response.prompt_tokens
        Rails.logger.info(
          "[AI] #{action_name} - Tokens: prompt=#{response.prompt_tokens}, " \
          "completion=#{response.completion_tokens}, total=#{response.total_tokens}"
        )
      end
    end
  end
end
