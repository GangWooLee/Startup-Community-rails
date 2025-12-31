# frozen_string_literal: true

# Faraday SSL 설정
# Mac에서 SSL 인증서 검증 문제 해결
#
# ## 문제 상황
# Mac (macOS) 환경에서 Gemini API 호출 시 다음 에러 발생:
#   "certificate verify failed (unable to get certificate CRL)"
#
# ## 원인
# Mac의 OpenSSL이 Certificate Revocation List (CRL) 검증을 시도하지만
# Homebrew OpenSSL 3.6.0 환경에서 CRL 검증이 실패함
#
# ## 해결책
# 개발 환경에서만 SSL 검증을 비활성화합니다.
#
# ## 플랫폼별 동작
# - Mac (darwin): 이 설정이 필요함 (SSL 에러 방지)
# - Linux (Ubuntu 등): 이 설정이 없어도 작동하지만, 있어도 무해함
# - Windows: 테스트 필요 (WSL 환경에서는 Linux와 동일)
#
# ⚠️ **중요**: Mac-Ubuntu 환경을 오가는 경우 이 파일을 삭제하지 마세요!
#              Mac에서 다시 SSL 에러가 발생합니다.
#
# ⚠️ **주의**: 프로덕션 환경에서는 절대 SSL 검증을 비활성화하지 마세요!
#              아래 조건문으로 개발/테스트 환경만 적용됩니다.

if Rails.env.development? || Rails.env.test?
  require "faraday"
  require "openssl"

  # OpenSSL SSL 검증 완전 비활성화 (개발 환경만)
  # CRL 검증 오류를 방지하기 위해 VERIFY_NONE 사용
  OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:verify_mode] = OpenSSL::SSL::VERIFY_NONE

  # Faraday 기본 SSL 옵션 설정
  Faraday.default_connection_options = {
    ssl: {
      verify: false  # SSL 검증 비활성화 (개발 환경만)
    }
  }

  Rails.logger.warn "[Faraday] ⚠️  SSL verification DISABLED for development environment (Mac CRL issue workaround)"
end
