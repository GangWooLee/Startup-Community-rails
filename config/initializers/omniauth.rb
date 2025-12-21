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
# GET과 POST 모두 허용
# 참고: CSRF 보호는 oauth_controller#passthru에서 Rails의 CSRF 토큰 검증으로 처리됨
# 외부에서 직접 /auth/:provider로 GET 요청 시에도 OmniAuth가 처리하도록 허용
OmniAuth.config.allowed_request_methods = [:get, :post]

# 인증 실패 시 예외 발생 대신 failure 엔드포인트로 리다이렉트
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
