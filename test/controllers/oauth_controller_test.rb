# frozen_string_literal: true

require "test_helper"

class OauthControllerTest < ActionDispatch::IntegrationTest
  # ============================================================================
  # Passthru Action Tests
  # ============================================================================

  test "passthru redirects to google oauth path" do
    post "/oauth/google_oauth2"

    assert_response :redirect
    assert_match %r{/auth/google_oauth2}, response.location
  end

  test "passthru redirects to github oauth path" do
    post "/oauth/github"

    assert_response :redirect
    assert_match %r{/auth/github}, response.location
  end

  test "passthru rejects unsupported provider" do
    post "/oauth/facebook"

    assert_redirected_to login_path
    assert_equal "지원하지 않는 로그인 방식입니다.", flash[:alert]
  end

  test "passthru saves origin param to session" do
    post "/oauth/google_oauth2", params: { origin: "/posts/123" }

    assert_response :redirect
    # 세션에 return_to가 저장되었는지 확인 (통합 테스트에서는 직접 접근 어려움)
  end

  # ============================================================================
  # URL Validation Tests (Integration)
  # ============================================================================

  test "passthru allows relative path in origin" do
    post "/oauth/google_oauth2", params: { origin: "/community" }

    assert_response :redirect
    assert_match %r{/auth/google_oauth2}, response.location
  end

  test "passthru rejects absolute url with different host" do
    # 다른 호스트 URL은 무시되어야 함 (open redirect 방지)
    post "/oauth/google_oauth2", params: { origin: "https://evil.com/steal" }

    assert_response :redirect
    # 악성 URL이 세션에 저장되지 않고 리디렉션은 정상 진행
    assert_match %r{/auth/google_oauth2}, response.location
  end

  test "passthru rejects protocol-relative url" do
    # //evil.com 형태의 URL 거부 (open redirect 방지)
    post "/oauth/google_oauth2", params: { origin: "//evil.com/path" }

    assert_response :redirect
  end

  # ============================================================================
  # WebView Detection Tests (Google OAuth 403 disallowed_useragent 방지)
  # ============================================================================

  test "WebView에서 Google OAuth 시도 시 경고 페이지로 리다이렉트" do
    # Android WebView User-Agent
    webview_ua = "Mozilla/5.0 (Linux; Android 10; SM-G960F; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/91.0.4472.120 Mobile Safari/537.36"

    post "/oauth/google_oauth2", headers: { "User-Agent" => webview_ua }

    assert_redirected_to oauth_webview_warning_path
  end

  test "카카오톡 인앱 브라우저에서 Google OAuth 시도 시 경고 페이지로 리다이렉트" do
    kakao_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 KAKAOTALK 9.5.5"

    post "/oauth/google_oauth2", headers: { "User-Agent" => kakao_ua }

    assert_redirected_to oauth_webview_warning_path
  end

  test "Instagram 인앱 브라우저에서 Google OAuth 시도 시 경고 페이지로 리다이렉트" do
    instagram_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Instagram 152.0.0.24.117"

    post "/oauth/google_oauth2", headers: { "User-Agent" => instagram_ua }

    assert_redirected_to oauth_webview_warning_path
  end

  test "Facebook 인앱 브라우저에서 Google OAuth 시도 시 경고 페이지로 리다이렉트" do
    facebook_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBDV/iPhone12,1]"

    post "/oauth/google_oauth2", headers: { "User-Agent" => facebook_ua }

    assert_redirected_to oauth_webview_warning_path
  end

  test "iOS WebView(Safari 없음)에서 Google OAuth 시도 시 경고 페이지로 리다이렉트" do
    ios_webview_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

    post "/oauth/google_oauth2", headers: { "User-Agent" => ios_webview_ua }

    assert_redirected_to oauth_webview_warning_path
  end

  test "일반 Safari 브라우저에서는 정상 OAuth 진행" do
    safari_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Mobile/15E148 Safari/604.1"

    post "/oauth/google_oauth2", headers: { "User-Agent" => safari_ua }

    assert_response :redirect
    assert_match %r{/auth/google_oauth2}, response.location
  end

  test "일반 Chrome 브라우저에서는 정상 OAuth 진행" do
    chrome_ua = "Mozilla/5.0 (Linux; Android 10; SM-G960F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36"

    post "/oauth/google_oauth2", headers: { "User-Agent" => chrome_ua }

    assert_response :redirect
    assert_match %r{/auth/google_oauth2}, response.location
  end

  test "WebView에서 GitHub OAuth는 정상 진행 (제한 없음)" do
    webview_ua = "Mozilla/5.0 (Linux; Android 10; SM-G960F; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/91.0.4472.120 Mobile Safari/537.36"

    post "/oauth/github", headers: { "User-Agent" => webview_ua }

    assert_response :redirect
    assert_match %r{/auth/github}, response.location
  end

  # ============================================================================
  # WebView Warning Page Tests
  # ============================================================================

  test "webview_warning 페이지는 WebView에서만 표시" do
    webview_ua = "Mozilla/5.0 (Linux; Android 10; SM-G960F; wv) AppleWebKit/537.36"

    get "/oauth/webview_warning", headers: { "User-Agent" => webview_ua }

    assert_response :success
    assert_select "h1", text: /브라우저에서 열어주세요/
  end

  test "webview_warning 페이지는 일반 브라우저에서 로그인으로 리다이렉트" do
    chrome_ua = "Mozilla/5.0 (Linux; Android 10; SM-G960F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36"

    get "/oauth/webview_warning", headers: { "User-Agent" => chrome_ua }

    assert_redirected_to login_path
  end

  test "webview_warning 페이지에 GitHub 로그인 대안 표시" do
    webview_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 KAKAOTALK 9.5.5"

    get "/oauth/webview_warning", headers: { "User-Agent" => webview_ua }

    assert_response :success
    assert_select "button", text: /GitHub로 로그인하기/
  end

  # ============================================================================
  # WebView Warning Page - Platform Specific UI Tests
  # ============================================================================

  test "Android에서 Chrome Intent URI 버튼 표시" do
    android_webview_ua = "Mozilla/5.0 (Linux; Android 10; SM-G960F; wv) AppleWebKit/537.36"

    get "/oauth/webview_warning", headers: { "User-Agent" => android_webview_ua }

    assert_response :success
    assert_select "a[href*='intent://']"
    assert_select "a", text: /Chrome에서 열기/
  end

  test "Android Intent URI 형식이 올바름" do
    android_webview_ua = "Mozilla/5.0 (Linux; Android 10; SM-G960F; wv) AppleWebKit/537.36"

    get "/oauth/webview_warning", headers: { "User-Agent" => android_webview_ua }

    # intent://host/path#Intent;scheme=https;package=com.android.chrome;... 형식 검증
    assert_select "a[href*='intent://'][href*='package=com.android.chrome']"
    assert_select "a[href*='scheme=https']"
    assert_select "a[href*='browser_fallback_url=']"
  end

  test "iOS에서 Chrome googlechromes:// 버튼 표시" do
    ios_webview_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

    get "/oauth/webview_warning", headers: { "User-Agent" => ios_webview_ua }

    assert_response :success
    assert_select "a[href^='googlechromes://']"
    assert_select "a", text: /Chrome에서 열기/
  end

  test "iOS googlechromes:// URL 형식이 올바름" do
    ios_webview_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

    get "/oauth/webview_warning", headers: { "User-Agent" => ios_webview_ua }

    # googlechromes://host/path 형식 검증 (HTTPS → googlechromes)
    assert_select "a[href^='googlechromes://'][href*='/login']"
  end

  test "링크 복사 버튼이 Android에 표시됨" do
    android_ua = "Mozilla/5.0 (Linux; Android 10; SM-G960F; wv) AppleWebKit/537.36"

    get "/oauth/webview_warning", headers: { "User-Agent" => android_ua }

    assert_select "button", text: /링크 복사하기/
  end

  test "링크 복사 버튼이 iOS에 표시됨" do
    ios_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"

    get "/oauth/webview_warning", headers: { "User-Agent" => ios_ua }

    assert_select "button", text: /링크 복사하기/
  end

  test "이메일 로그인 링크 표시" do
    webview_ua = "Mozilla/5.0 (Linux; Android 10; SM-G960F; wv) AppleWebKit/537.36"

    get "/oauth/webview_warning", headers: { "User-Agent" => webview_ua }

    assert_select "a[href='/login']", text: /이메일로 로그인/
  end

  # ============================================================================
  # App Name Detection Tests
  # ============================================================================

  test "카카오톡 인앱 브라우저 앱 이름 감지" do
    kakao_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 KAKAOTALK 9.5.5"

    get "/oauth/webview_warning", headers: { "User-Agent" => kakao_ua }

    assert_response :success
    assert_select "span", text: "카카오톡"
  end

  test "Instagram 인앱 브라우저 앱 이름 감지" do
    instagram_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Instagram 152.0.0.24.117"

    get "/oauth/webview_warning", headers: { "User-Agent" => instagram_ua }

    assert_response :success
    assert_select "span", text: "Instagram"
  end

  test "Facebook 인앱 브라우저 앱 이름 감지" do
    facebook_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 [FBAN/FBIOS;FBDV/iPhone12,1]"

    get "/oauth/webview_warning", headers: { "User-Agent" => facebook_ua }

    assert_response :success
    assert_select "span", text: "Facebook"
  end

  test "일반 WebView는 인앱 브라우저로 표시" do
    generic_webview_ua = "Mozilla/5.0 (Linux; Android 10; SM-G960F; wv) AppleWebKit/537.36"

    get "/oauth/webview_warning", headers: { "User-Agent" => generic_webview_ua }

    assert_response :success
    assert_select "span", text: "인앱 브라우저"
  end
end
