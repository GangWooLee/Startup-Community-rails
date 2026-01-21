# frozen_string_literal: true

# 세션 쿠키 설정
#
# 보안 설정:
# - httponly: true  → JavaScript에서 세션 쿠키 접근 차단 (XSS 방어)
# - secure: true    → HTTPS에서만 쿠키 전송 (프로덕션)
# - same_site: :lax → CSRF 방어 (일반 링크 허용, POST 요청 차단)
#
# Hotwire Native 앱 호환:
# - httponly: true는 앱 WebView에서도 정상 작동
# - 앱은 Keychain/Keystore에 토큰을 별도 저장하므로 영향 없음
#
Rails.application.config.session_store :cookie_store,
  key: "_startup_community_session",
  same_site: :lax,
  secure: Rails.env.production?,
  httponly: true
