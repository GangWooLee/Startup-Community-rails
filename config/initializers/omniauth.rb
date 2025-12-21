Rails.application.config.middleware.use OmniAuth::Builder do
  # Google OAuth2
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"],
    {
      scope: "email, profile",
      prompt: "select_account",
      image_aspect_ratio: "square",
      image_size: 50,
      # 환경별 redirect_uri 설정
      redirect_uri: ENV.fetch("GOOGLE_OAUTH_REDIRECT_URI") {
        Rails.env.production? ? nil : "http://localhost:3000/auth/google_oauth2/callback"
      }
    }

  # GitHub OAuth
  provider :github, ENV["GITHUB_CLIENT_ID"], ENV["GITHUB_CLIENT_SECRET"],
    {
      scope: "user:email"
    }
end

# OmniAuth 보안 설정
# POST 요청만 허용 (OAuth 2.0 보안 표준)
OmniAuth.config.allowed_request_methods = [:post]

# 인증 실패 시 예외 발생 대신 failure 엔드포인트로 리다이렉트
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
