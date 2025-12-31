# frozen_string_literal: true

# LangchainRB Configuration
# AI Agent framework 설정

# LLM Provider 설정
# Rails credentials에서 API 키를 가져옴
#
# 사용법:
#   OpenAI: credentials.dig(:openai, :api_key)
#   Gemini: credentials.dig(:gemini, :api_key)
#
# credentials 설정:
#   EDITOR="code --wait" bin/rails credentials:edit

module LangchainConfig
  class << self
    # OpenAI LLM 인스턴스 생성
    def openai_llm(model: "gpt-4o-mini", temperature: 0.7)
      api_key = Rails.application.credentials.dig(:openai, :api_key)

      raise "OpenAI API key not configured. Run: EDITOR='code --wait' bin/rails credentials:edit" if api_key.blank?

      Langchain::LLM::OpenAI.new(
        api_key: api_key,
        default_options: {
          temperature: temperature,
          chat_model: model
        }
      )
    end

    # Google Gemini LLM 인스턴스 생성
    def gemini_llm(model: "gemini-2.0-flash", temperature: 0.7)
      api_key = gemini_api_key

      raise "Gemini API key not configured. Run: EDITOR='code --wait' bin/rails credentials:edit" if api_key.blank?

      Langchain::LLM::GoogleGemini.new(
        api_key: api_key,
        default_options: {
          temperature: temperature,
          chat_model: model,
          # SSL 검증 비활성화 (개발 환경)
          request: {
            open_timeout: 60,
            read_timeout: 60
          }
        }
      )
    end

    # Gemini API 키 조회 (여러 경로에서 탐색)
    def gemini_api_key
      Rails.application.credentials.dig(:gemini, :api_key) ||
        Rails.application.credentials.dig(:google, :gemini_api_key) ||
        ENV["GOOGLE_GEMINI_API_KEY"] ||
        ENV["GEMINI_API_KEY"]
    end

    # 기본 LLM 제공자 (credentials에서 설정)
    def default_llm(temperature: 0.7)
      provider = Rails.application.credentials.fetch(:default_llm_provider, "gemini")

      case provider.to_s.downcase
      when "openai"
        openai_llm(temperature: temperature)
      when "gemini"
        gemini_llm(temperature: temperature)
      else
        raise "Unknown LLM provider: #{provider}. Use 'openai' or 'gemini'"
      end
    end

    # API 키 설정 여부 확인
    def openai_configured?
      Rails.application.credentials.dig(:openai, :api_key).present?
    end

    def gemini_configured?
      gemini_api_key.present?
    end

    def any_llm_configured?
      openai_configured? || gemini_configured?
    end

    # 에이전트별 최적화된 LLM 설정
    # 간단한 작업(요약)은 저렴한 모델, 복잡한 분석은 고성능 모델 사용
    # Gemini 3 Flash (2025-12-17 출시) - Pro 수준 지능, Flash 가격
    # summary는 비용 절감을 위해 flash-lite 유지
    AGENT_MODEL_CONFIGS = {
      summary: { model: "gemini-2.0-flash-lite", temperature: 0.5 },
      target_user: { model: "gemini-3-flash-preview", temperature: 0.7 },
      market_analysis: { model: "gemini-3-flash-preview", temperature: 0.7 },
      strategy: { model: "gemini-3-flash-preview", temperature: 0.7 },
      scoring: { model: "gemini-3-flash-preview", temperature: 0.5 }
    }.freeze

    # 에이전트 타입에 맞는 LLM 인스턴스 생성
    # @param agent_type [Symbol] :summary, :target_user, :market_analysis, :strategy, :scoring
    # @return [Langchain::LLM::GoogleGemini] 에이전트에 최적화된 LLM 인스턴스
    def llm_for_agent(agent_type)
      config = AGENT_MODEL_CONFIGS[agent_type] || { model: "gemini-2.0-flash", temperature: 0.7 }
      gemini_llm(model: config[:model], temperature: config[:temperature])
    end
  end
end
