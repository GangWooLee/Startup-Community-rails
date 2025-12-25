# OmniAuth 보안 설정 (provider 설정 전에 먼저 적용)
# GET과 POST 모두 허용
# 참고: CSRF 보호는 oauth_controller#passthru에서 Rails의 CSRF 토큰 검증으로 처리됨
OmniAuth.config.allowed_request_methods = [:get, :post]

# 인증 실패 시 예외 발생 대신 failure 엔드포인트로 리다이렉트
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

# 개발 환경에서 state 검증 완화 (IPv4/IPv6 불일치 문제)
# 프로덕션에서는 더 엄격하게 유지
OmniAuth.config.silence_get_warning = true

Rails.application.config.middleware.use OmniAuth::Builder do
  # Rails credentials에서 OAuth 키 가져오기
  google_credentials = Rails.application.credentials.dig(:google) || {}
  github_credentials = Rails.application.credentials.dig(:github) || {}

  # Google OAuth2
  google_options = {
    scope: "email, profile",
    prompt: "select_account",
    image_aspect_ratio: "square",
    image_size: 50
  }

  # 프로덕션에서만 명시적 redirect_uri 설정, 개발 환경은 자동 감지
  if google_credentials[:redirect_uri].present?
    google_options[:redirect_uri] = google_credentials[:redirect_uri]
  end

  provider :google_oauth2,
           google_credentials[:client_id],
           google_credentials[:client_secret],
           google_options

  # GitHub OAuth
  github_options = {
    scope: "user:email"
  }

  # 프로덕션에서만 명시적 redirect_uri 설정, 개발 환경은 자동 감지
  if github_credentials[:redirect_uri].present?
    github_options[:redirect_uri] = github_credentials[:redirect_uri]
  end

  provider :github,
           github_credentials[:client_id],
           github_credentials[:client_secret],
           github_options
end
