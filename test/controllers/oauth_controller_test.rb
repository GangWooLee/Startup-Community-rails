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
    assert_equal "/posts/123", session[:return_to]
  end

  test "passthru saves origin to oauth_return_to session for WebView redirect" do
    kakao_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 KAKAOTALK 9.5.5"

    post "/oauth/google_oauth2",
         params: { origin: "/posts/123" },
         headers: { "User-Agent" => kakao_ua }

    assert_redirected_to oauth_webview_warning_path
    assert_equal "/posts/123", session[:oauth_return_to]
  end

  test "passthru uses cookies[:return_to] when origin param absent" do
    cookies[:return_to] = "/profile/settings"

    post "/oauth/google_oauth2"

    assert_response :redirect
    assert_equal "/profile/settings", session[:return_to]
  end

  test "passthru prefers params[:origin] over cookies[:return_to]" do
    cookies[:return_to] = "/profile"

    post "/oauth/google_oauth2", params: { origin: "/community" }

    assert_response :redirect
    assert_equal "/community", session[:return_to]
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
    assert_nil session[:return_to]
  end

  test "passthru rejects protocol-relative url" do
    # //evil.com 형태의 URL 거부 (open redirect 방지)
    post "/oauth/google_oauth2", params: { origin: "//evil.com/path" }

    assert_response :redirect
    assert_nil session[:return_to]
  end

  test "passthru rejects javascript: URL in origin" do
    post "/oauth/google_oauth2", params: { origin: "javascript:alert('xss')" }

    assert_response :redirect
    assert_match %r{/auth/google_oauth2}, response.location
    # XSS 방지: javascript: 스킴 URL은 세션에 저장되지 않아야 함
    assert_nil session[:return_to]
  end

  test "passthru rejects data: URL in origin" do
    post "/oauth/google_oauth2", params: { origin: "data:text/html,<script>alert('xss')</script>" }

    assert_response :redirect
    assert_match %r{/auth/google_oauth2}, response.location
    # XSS 방지: data: 스킴 URL은 세션에 저장되지 않아야 함
    assert_nil session[:return_to]
  end

  test "passthru accepts absolute URL with same host and extracts path" do
    post "/oauth/google_oauth2", params: { origin: "http://www.example.com/posts/123" }

    assert_response :redirect
    # 같은 호스트의 절대 URL은 path만 추출하여 저장
    assert_equal "/posts/123", session[:return_to]
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

  # ============================================================================
  # KakaoTalk Specific Tests (외부 브라우저 자동 열기)
  # ============================================================================

  test "카카오톡 iOS에서 Chrome/Safari 버튼 표시" do
    kakao_ios_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 KAKAOTALK 9.5.5"

    get "/oauth/webview_warning", headers: { "User-Agent" => kakao_ios_ua }

    assert_response :success
    # iOS 카카오톡: Chrome 버튼 (Primary) + Safari 버튼 (Secondary)
    assert_select "a#kakao-chrome-btn", text: /Chrome에서 열기/
    assert_select "a#kakao-safari-btn", text: /Safari에서 열기/
  end

  test "카카오톡 Android에서 외부 브라우저 열기 버튼 표시" do
    kakao_android_ua = "Mozilla/5.0 (Linux; Android 11; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36 KAKAOTALK"

    get "/oauth/webview_warning", headers: { "User-Agent" => kakao_android_ua }

    assert_response :success
    # Android 카카오톡: 기존 외부 브라우저 버튼
    assert_select "a#kakao-external-btn", text: /외부 브라우저로 열기/
  end

  test "카카오톡에서 kakaotalk://web/openExternal 스킴 URL 생성" do
    kakao_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 KAKAOTALK 9.5.5"

    get "/oauth/webview_warning", headers: { "User-Agent" => kakao_ua }

    assert_response :success
    # kakaotalk://web/openExternal?url=... 형식 검증
    assert_select "a[href^='kakaotalk://web/openExternal?url=']"
  end

  test "카카오톡에서 JavaScript 자동 외부 브라우저 열기 스크립트 포함" do
    kakao_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 KAKAOTALK 9.5.5"

    get "/oauth/webview_warning", headers: { "User-Agent" => kakao_ua }

    assert_response :success
    # JavaScript에서 kakaotalk:// 스킴 사용
    assert_match /kakaotalk:\/\/web\/openExternal/, response.body
    assert_match /setTimeout/, response.body
  end

  test "iOS 카카오톡에서 visibilitychange 이벤트 기반 Chrome 감지 스크립트 포함" do
    kakao_ios_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 KAKAOTALK 9.5.5"

    get "/oauth/webview_warning", headers: { "User-Agent" => kakao_ios_ua }

    assert_response :success

    # visibilitychange 이벤트 리스너 검증 (Chrome 열림 감지용)
    assert_match(/visibilitychange/, response.body)

    # clearTimeout 로직 검증 (Chrome 열리면 Safari 폴백 취소)
    assert_match(/clearTimeout/, response.body)

    # chromeOpened 플래그 검증 (상태 추적 변수)
    assert_match(/chromeOpened/, response.body)

    # 3.5초 타임아웃 검증 (기존 1초 → 3.5초로 변경됨, 충분한 갭 확보)
    assert_match(/3500/, response.body)

    # 이중 조건 체크 검증 (안전한 Safari 폴백 조건)
    assert_match(/!chromeOpened && !document\.hidden/, response.body)
  end

  test "Instagram에서는 카카오톡 전용 버튼 미표시" do
    instagram_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Instagram 152.0.0.24.117"

    get "/oauth/webview_warning", headers: { "User-Agent" => instagram_ua }

    assert_response :success
    # 카카오톡 버튼 없음
    assert_select "a#kakao-external-btn", count: 0
  end

  test "일반 Android WebView에서는 카카오톡 전용 버튼 미표시" do
    android_webview_ua = "Mozilla/5.0 (Linux; Android 10; SM-G960F; wv) AppleWebKit/537.36"

    get "/oauth/webview_warning", headers: { "User-Agent" => android_webview_ua }

    assert_response :success
    # 카카오톡 버튼 없음, Chrome 버튼은 있음
    assert_select "a#kakao-external-btn", count: 0
    assert_select "a[href*='intent://']"
  end

  test "카카오톡 Android에서도 외부 브라우저 열기 버튼 표시" do
    kakao_android_ua = "Mozilla/5.0 (Linux; Android 11; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36 KAKAOTALK"

    get "/oauth/webview_warning", headers: { "User-Agent" => kakao_android_ua }

    assert_response :success
    # 카카오톡 전용 버튼
    assert_select "a#kakao-external-btn", text: /외부 브라우저로 열기/
    # Chrome Intent 버튼도 폴백으로 표시
    assert_select "a[href*='intent://']"
  end

  test "카카오톡 외부 브라우저 URL이 올바르게 인코딩됨" do
    kakao_ua = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 KAKAOTALK 9.5.5"

    get "/oauth/webview_warning", headers: { "User-Agent" => kakao_ua }

    assert_response :success
    # URL이 CGI.escape로 인코딩되었는지 확인
    assert_select "a[href*='kakaotalk://web/openExternal?url=']"
    # ://가 인코딩되어 %3A%2F%2F로 표시됨
    assert_match /%3A%2F%2F/, response.body
  end

  test "일반 WebView에서는 카카오톡 JavaScript 미포함" do
    generic_webview_ua = "Mozilla/5.0 (Linux; Android 10; SM-G960F; wv) AppleWebKit/537.36"

    get "/oauth/webview_warning", headers: { "User-Agent" => generic_webview_ua }

    assert_response :success
    # 카카오톡 자동 열기 스크립트 없음
    assert_no_match /kakaotalk:\/\/web\/openExternal/, response.body
  end
end
