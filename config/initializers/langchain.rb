# frozen_string_literal: true

# LangchainRB 초기화
# Rails autoload가 lib/langchain_config.rb를 자동 로드함
# 이 파일은 초기화 시점에 LangchainConfig 모듈이 로드되도록 보장

Rails.application.config.after_initialize do
  # LangchainConfig 모듈 로드 확인
  LangchainConfig
rescue NameError => e
  Rails.logger.warn "[Langchain] LangchainConfig not loaded: #{e.message}"
end
