# frozen_string_literal: true

# LangchainRB 초기화
# Rails autoload가 lib/langchain_config.rb를 자동 로드함
# 이 파일은 초기화 시점에 LangchainConfig 모듈이 로드되도록 보장

Rails.application.config.after_initialize do
  # LangchainConfig 모듈 로드 확인
  LangchainConfig
rescue NameError => e
  # 프로덕션에서 AI 기능이 필수인 경우 시작 실패 (AI_OPTIONAL=true로 우회 가능)
  if Rails.env.production? && !ENV["AI_OPTIONAL"].present?
    Rails.logger.error "[Langchain] LangchainConfig 로드 실패 - AI 기능 비활성화됨: #{e.message}"
    Rails.logger.error "[Langchain] AI 기능 없이 시작하려면 AI_OPTIONAL=true 환경변수를 설정하세요"
    raise "LangchainConfig 로드 실패: #{e.message}"
  else
    Rails.logger.warn "[Langchain] LangchainConfig not loaded (non-production): #{e.message}"
  end
end
