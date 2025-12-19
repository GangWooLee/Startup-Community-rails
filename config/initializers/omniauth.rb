Rails.application.config.middleware.use OmniAuth::Builder do
  # Google OAuth2
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"],
    {
      scope: "email, profile",
      prompt: "select_account",
      image_aspect_ratio: "square",
      image_size: 50,
      provider_ignores_state: true,  # CSRF state 검증 비활성화
      redirect_uri: "http://localhost:3000/auth/google_oauth2/callback"
    }

  # GitHub OAuth
  provider :github, ENV["GITHUB_CLIENT_ID"], ENV["GITHUB_CLIENT_SECRET"],
    {
      scope: "user:email",
      provider_ignores_state: true  # CSRF state 검증 비활성화
    }
end

# OmniAuth 설정
OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true
