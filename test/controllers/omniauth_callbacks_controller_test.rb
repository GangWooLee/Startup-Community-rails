# frozen_string_literal: true

require "test_helper"

class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
    @test_idea = "OAuth 테스트 아이디어 #{SecureRandom.hex(4)}"
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.mock_auth[:github] = nil
  end

  # ============================================================================
  # Phase 5: OAuth Session Recovery Tests (OAuth 세션 복구 테스트)
  # ============================================================================

  test "OAuth callback creates new user when not exists" do
    unique_email = "new_oauth_user_#{SecureRandom.hex(4)}@gmail.com"
    unique_uid = "new_uid_#{SecureRandom.hex(8)}"

    # 이 이메일을 가진 사용자가 없는지 확인
    assert_nil User.find_by(email: unique_email), "Precondition: user should not exist"

    # OAuth Mock 설정 (신규 사용자) - google_oauth2가 아닌 google 키 사용
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: unique_uid,
      info: {
        email: unique_email,
        name: "New OAuth User",
        image: "https://example.com/avatar.jpg"
      }
    })

    # OAuth 콜백 호출 - OauthIdentity도 같이 생성됨
    assert_difference [ "User.count", "OauthIdentity.count" ], 1 do
      get "/auth/google_oauth2/callback"
    end

    # 새 사용자 생성 확인
    new_user = User.find_by(email: unique_email)
    assert new_user.present?, "Expected new user to be created"
    # OauthIdentity로 연결 확인
    assert new_user.oauth_identities.exists?(provider: "google_oauth2", uid: unique_uid),
           "Expected OAuth identity to be created"
  end

  test "OAuth callback finds existing user by OauthIdentity" do
    # 기존 사용자에 OAuth 정보 설정
    oauth_uid = "existing_uid_#{SecureRandom.hex(8)}"
    @user.oauth_identities.create!(provider: "google_oauth2", uid: oauth_uid)

    # OAuth Mock 설정 (기존 사용자)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: oauth_uid,
      info: {
        email: @user.email,
        name: @user.name,
        image: "https://example.com/avatar.jpg"
      }
    })

    # OAuth 콜백 호출 - 새 사용자 생성되지 않음
    assert_no_difference "User.count" do
      get "/auth/google_oauth2/callback"
    end

    # 리다이렉트 확인 (커뮤니티 또는 결과 페이지)
    assert_response :redirect
  end

  test "OAuth failure redirects to login with error message" do
    # 실패 콜백 URL 직접 호출
    get "/auth/failure", params: { message: "access_denied" }

    # 로그인 페이지로 리다이렉트 확인
    assert_redirected_to login_path
    assert flash[:alert].present?, "Expected alert flash message for OAuth failure"
  end

  # ============================================================================
  # Phase 1.2: OAuth 필수 필드 검증 테스트 (보안 강화)
  # ============================================================================

  test "OAuth callback rejects nil auth data" do
    # omniauth.auth가 nil인 경우 - OmniAuth failure 시뮬레이션
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

    assert_no_difference "User.count" do
      get "/auth/google_oauth2/callback"
    end

    # failure 경로로 리다이렉트됨
    assert_response :redirect
  end

  test "OAuth callback rejects auth without email" do
    # email이 없는 OAuth 응답 (일부 provider에서 발생 가능)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "uid_without_email_#{SecureRandom.hex(8)}",
      info: {
        name: "User Without Email",
        image: "https://example.com/avatar.jpg"
        # email 필드 누락
      }
    })

    assert_no_difference "User.count" do
      get "/auth/google_oauth2/callback"
    end

    assert_redirected_to login_path
    assert_equal "로그인에 실패했습니다. 다시 시도해주세요.", flash[:alert]
  end

  test "OAuth callback rejects auth without uid" do
    # uid가 없는 OAuth 응답
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      # uid 필드 누락
      info: {
        email: "no_uid_user@example.com",
        name: "User Without UID"
      }
    })

    assert_no_difference "User.count" do
      get "/auth/google_oauth2/callback"
    end

    assert_redirected_to login_path
    assert_equal "로그인에 실패했습니다. 다시 시도해주세요.", flash[:alert]
  end

  test "OAuth callback rejects auth without provider" do
    # provider가 없는 OAuth 응답
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      # provider 필드 누락
      uid: "uid_without_provider_#{SecureRandom.hex(8)}",
      info: {
        email: "no_provider_user@example.com",
        name: "User Without Provider"
      }
    })

    assert_no_difference "User.count" do
      get "/auth/google_oauth2/callback"
    end

    assert_redirected_to login_path
    assert_equal "로그인에 실패했습니다. 다시 시도해주세요.", flash[:alert]
  end

  test "OAuth callback rejects auth with empty email string" do
    # email이 빈 문자열인 경우
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "uid_empty_email_#{SecureRandom.hex(8)}",
      info: {
        email: "",  # 빈 문자열
        name: "User With Empty Email"
      }
    })

    assert_no_difference "User.count" do
      get "/auth/google_oauth2/callback"
    end

    assert_redirected_to login_path
    assert_equal "로그인에 실패했습니다. 다시 시도해주세요.", flash[:alert]
  end
end
