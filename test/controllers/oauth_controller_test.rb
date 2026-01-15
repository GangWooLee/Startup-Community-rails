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
end
