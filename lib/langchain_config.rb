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
      api_key = Rails.application.credentials.dig(:gemini, :api_key)

      raise "Gemini API key not configured. Run: EDITOR='code --wait' bin/rails credentials:edit" if api_key.blank?

      Langchain::LLM::GoogleGemini.new(
        api_key: api_key,
        default_options: {
          temperature: temperature,
          chat_model: model
        }
      )
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
      Rails.application.credentials.dig(:gemini, :api_key).present?
    end

    def any_llm_configured?
      openai_configured? || gemini_configured?
    end
  end
end
