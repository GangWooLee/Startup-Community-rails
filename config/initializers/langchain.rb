# frozen_string_literal: true

# LangchainRB Configuration
# AI Agent framework 설정

# LLM Provider 설정
# 환경변수 또는 Rails credentials에서 API 키를 가져옴
#
# 사용법:
#   OpenAI: OPENAI_API_KEY 환경변수 또는 credentials.dig(:openai, :api_key)
#   Gemini: GEMINI_API_KEY 환경변수 또는 credentials.dig(:gemini, :api_key)

module LangchainConfig
  class << self
    # OpenAI LLM 인스턴스 생성
    def openai_llm(model: "gpt-4o-mini", temperature: 0.7)
      api_key = ENV["OPENAI_API_KEY"] || Rails.application.credentials.dig(:openai, :api_key)

      raise "OpenAI API key not configured" if api_key.blank?

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
      api_key = ENV["GEMINI_API_KEY"] || Rails.application.credentials.dig(:gemini, :api_key)

      raise "Gemini API key not configured" if api_key.blank?

      Langchain::LLM::GoogleGemini.new(
        api_key: api_key,
        default_options: {
          temperature: temperature,
          chat_model: model
        }
      )
    end

    # 기본 LLM 제공자 (환경변수로 전환 가능)
    # DEFAULT_LLM_PROVIDER: "openai" 또는 "gemini"
    def default_llm(temperature: 0.7)
      provider = ENV.fetch("DEFAULT_LLM_PROVIDER", "gemini")

      case provider.downcase
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
      api_key = ENV["OPENAI_API_KEY"] || Rails.application.credentials.dig(:openai, :api_key)
      api_key.present?
    end

    def gemini_configured?
      api_key = ENV["GEMINI_API_KEY"] || Rails.application.credentials.dig(:gemini, :api_key)
      api_key.present?
    end

    def any_llm_configured?
      openai_configured? || gemini_configured?
    end
  end
end
