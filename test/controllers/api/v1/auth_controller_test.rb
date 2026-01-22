# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class AuthControllerTest < ActionDispatch::IntegrationTest
      fixtures :users

      setup do
        @user = users(:one)
        # Hotwire Native 앱 User-Agent 헤더
        @native_app_headers = {
          "User-Agent" => "Mozilla/5.0 (iPhone) AppleWebKit/537.36 Turbo Native/1.0"
        }
        @web_headers = {
          "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X)"
        }
      end

      # ==========================================================================
      # POST /api/v1/auth/token (토큰 발급)
      # ==========================================================================

      test "POST /api/v1/auth/token - 로그인 상태에서 토큰 발급 성공" do
        # 먼저 로그인
        log_in_as(@user)

        post api_v1_auth_url, headers: @native_app_headers

        assert_response :created
        json = JSON.parse(response.body)

        assert json["success"]
        assert_not_nil json["token"]
        assert_not_nil json["expires_at"]
        assert_not_nil json["user"]
        assert_equal @user.id, json["user"]["id"]
        assert_equal @user.display_name, json["user"]["name"]
      end

      test "POST /api/v1/auth/token - 비로그인 시 401 반환" do
        post api_v1_auth_url, headers: @native_app_headers

        assert_response :unauthorized
        json = JSON.parse(response.body)

        assert_not json["success"]
        assert_equal "Authentication required", json["message"]
      end

      test "POST /api/v1/auth/token - 웹 브라우저에서 접근 시 403 반환" do
        log_in_as(@user)

        post api_v1_auth_url, headers: @web_headers

        assert_response :forbidden
        json = JSON.parse(response.body)

        assert_not json["success"]
        assert_includes json["message"], "native apps"
      end

      # ==========================================================================
      # GET /api/v1/auth/validate (토큰 검증)
      # ==========================================================================

      test "GET /api/v1/auth/validate - 유효한 토큰으로 검증 성공" do
        # 토큰 발급
        log_in_as(@user)
        post api_v1_auth_url, headers: @native_app_headers
        token = JSON.parse(response.body)["token"]

        # 토큰 검증
        get validate_api_v1_auth_url, headers: @native_app_headers.merge(
          "Authorization" => "Bearer #{token}"
        )

        assert_response :ok
        json = JSON.parse(response.body)

        assert json["valid"]
        assert_not_nil json["user"]
        assert_equal @user.id, json["user"]["id"]
      end

      test "GET /api/v1/auth/validate - 토큰 없이 요청 시 401 반환" do
        get validate_api_v1_auth_url, headers: @native_app_headers

        assert_response :unauthorized
        json = JSON.parse(response.body)

        assert_not json["valid"]
        assert_includes json["message"], "Missing"
      end

      test "GET /api/v1/auth/validate - 잘못된 토큰으로 요청 시 401 반환" do
        get validate_api_v1_auth_url, headers: @native_app_headers.merge(
          "Authorization" => "Bearer invalid_token_here"
        )

        assert_response :unauthorized
        json = JSON.parse(response.body)

        assert_not json["valid"]
        assert_includes json["message"], "Invalid"
      end

      test "GET /api/v1/auth/validate - 잘못된 형식의 Bearer 토큰 시 401 반환" do
        # 특수문자 포함된 잘못된 형식
        get validate_api_v1_auth_url, headers: @native_app_headers.merge(
          "Authorization" => "Bearer <script>alert('xss')</script>"
        )

        assert_response :unauthorized
      end

      test "GET /api/v1/auth/validate - 만료된 토큰으로 요청 시 401 반환" do
        # 만료된 토큰 생성 (시간 조작)
        payload = {
          user_id: @user.id,
          exp: 1.day.ago.to_i,  # 이미 만료됨
          iat: 2.days.ago.to_i,
          purpose: "app_session"
        }
        expired_token = Rails.application.message_verifier("app_session")
                             .generate(payload, purpose: :app_session)

        get validate_api_v1_auth_url, headers: @native_app_headers.merge(
          "Authorization" => "Bearer #{expired_token}"
        )

        assert_response :unauthorized
        json = JSON.parse(response.body)

        assert_not json["valid"]
        assert_includes json["message"], "expired"
      end

      test "GET /api/v1/auth/validate - 존재하지 않는 사용자 ID 토큰 시 401 반환" do
        payload = {
          user_id: 999999,  # 존재하지 않는 ID
          exp: 30.days.from_now.to_i,
          iat: Time.current.to_i,
          purpose: "app_session"
        }
        invalid_user_token = Rails.application.message_verifier("app_session")
                                  .generate(payload, purpose: :app_session)

        get validate_api_v1_auth_url, headers: @native_app_headers.merge(
          "Authorization" => "Bearer #{invalid_user_token}"
        )

        assert_response :unauthorized
        json = JSON.parse(response.body)

        assert_not json["valid"]
        assert_includes json["message"], "User not found"
      end

      # ==========================================================================
      # DELETE /api/v1/auth/token (토큰 폐기/로그아웃)
      # ==========================================================================

      test "DELETE /api/v1/auth/token - 유효한 토큰으로 폐기 성공" do
        # 토큰 발급
        log_in_as(@user)
        post api_v1_auth_url, headers: @native_app_headers
        token = JSON.parse(response.body)["token"]

        # 토큰 폐기
        delete api_v1_auth_url, headers: @native_app_headers.merge(
          "Authorization" => "Bearer #{token}"
        )

        assert_response :ok
        json = JSON.parse(response.body)

        assert json["success"]
        assert_includes json["message"], "revoked"
      end

      test "DELETE /api/v1/auth/token - 토큰 없이 요청 시 401 반환" do
        delete api_v1_auth_url, headers: @native_app_headers

        assert_response :unauthorized
      end

      # ==========================================================================
      # 공통 보안 테스트
      # ==========================================================================

      test "모든 엔드포인트가 웹 브라우저에서 접근 불가" do
        # 토큰 발급
        log_in_as(@user)
        post api_v1_auth_url, headers: @web_headers
        assert_response :forbidden

        # 토큰 검증 (웹에서)
        get validate_api_v1_auth_url, headers: @web_headers
        assert_response :forbidden

        # 토큰 폐기 (웹에서)
        delete api_v1_auth_url, headers: @web_headers
        assert_response :forbidden
      end

      private

      def log_in_as(user)
        post login_url, params: { email: user.email, password: "test1234" }
      end
    end
  end
end
