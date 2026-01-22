# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class DevicesControllerTest < ActionDispatch::IntegrationTest
      fixtures :users, :devices

      setup do
        @user = users(:one)
        @device = devices(:ios_device)
        # Hotwire Native 앱 User-Agent 헤더 (form params용)
        @native_app_headers = {
          "User-Agent" => "Mozilla/5.0 (iPhone) AppleWebKit/537.36 Turbo Native/1.0"
        }
        @web_headers = {
          "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X)"
        }
      end

      # ==========================================================================
      # POST /api/v1/devices (디바이스 등록)
      # ==========================================================================

      test "POST /api/v1/devices - 새 디바이스 등록 성공" do
        log_in_as(@user)

        # 새 토큰 생성 (최소 50자)
        new_token = "fcm_new_device_token_#{SecureRandom.hex(24)}"

        assert_difference "Device.count", 1 do
          post api_v1_devices_url,
               params: {
                 platform: "ios",
                 token: new_token,
                 device_name: "iPhone 15 Pro Max",
                 app_version: "1.0.1"
               },
               headers: @native_app_headers
        end

        assert_response :created
        json = JSON.parse(response.body)

        assert json["success"]
        assert_not_nil json["device"]
        assert_equal "ios", json["device"]["platform"]
        assert json["device"]["enabled"]
      end

      test "POST /api/v1/devices - 기존 토큰 업데이트 성공" do
        log_in_as(@user)
        existing_token = @device.token

        assert_no_difference "Device.count" do
          post api_v1_devices_url,
               params: {
                 platform: "android",  # 플랫폼 변경
                 token: existing_token,
                 device_name: "Updated Device Name",
                 app_version: "2.0.0"
               },
               headers: @native_app_headers
        end

        assert_response :created
        json = JSON.parse(response.body)

        assert json["success"]
        @device.reload
        assert_equal "android", @device.platform
        assert_equal "Updated Device Name", @device.device_name
        assert_equal "2.0.0", @device.app_version
      end

      test "POST /api/v1/devices - 비로그인 시 401 반환" do
        new_token = "fcm_unauthorized_token_#{SecureRandom.hex(24)}"

        post api_v1_devices_url,
             params: {
               platform: "ios",
               token: new_token
             },
             headers: @native_app_headers

        assert_response :unauthorized
        json = JSON.parse(response.body)

        assert_not json["success"]
        assert_equal "Authentication required", json["message"]
      end

      test "POST /api/v1/devices - 웹 브라우저에서 접근 시 403 반환" do
        log_in_as(@user)
        new_token = "fcm_web_access_token_#{SecureRandom.hex(24)}"

        post api_v1_devices_url,
             params: {
               platform: "ios",
               token: new_token
             },
             headers: @web_headers

        assert_response :forbidden
      end

      test "POST /api/v1/devices - 유효하지 않은 플랫폼 시 422 반환" do
        log_in_as(@user)
        new_token = "fcm_invalid_platform_#{SecureRandom.hex(24)}"

        post api_v1_devices_url,
             params: {
               platform: "windows",  # 유효하지 않은 플랫폼
               token: new_token
             },
             headers: @native_app_headers

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert_not json["success"]
        assert_not_empty json["errors"]
      end

      test "POST /api/v1/devices - 토큰 길이 검증 (너무 짧음)" do
        log_in_as(@user)

        post api_v1_devices_url,
             params: {
               platform: "ios",
               token: "short"  # 50자 미만
             },
             headers: @native_app_headers

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert_not json["success"]
        assert json["errors"].any? { |e| e.include?("too short") }
      end

      test "POST /api/v1/devices - 토큰 길이 검증 (너무 긺)" do
        log_in_as(@user)

        post api_v1_devices_url,
             params: {
               platform: "ios",
               token: "a" * 1025  # 1024자 초과
             },
             headers: @native_app_headers

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert_not json["success"]
        assert json["errors"].any? { |e| e.include?("too long") }
      end

      # ==========================================================================
      # DELETE /api/v1/devices (디바이스 비활성화)
      # ==========================================================================

      test "DELETE /api/v1/devices - 디바이스 비활성화 성공" do
        log_in_as(@user)
        assert @device.enabled

        delete api_v1_devices_url,
               params: { token: @device.token },
               headers: @native_app_headers

        assert_response :ok
        json = JSON.parse(response.body)

        assert json["success"]
        @device.reload
        assert_not @device.enabled
      end

      test "DELETE /api/v1/devices - 존재하지 않는 토큰으로 요청 시 404 반환" do
        log_in_as(@user)

        delete api_v1_devices_url,
               params: { token: "fcm_nonexistent_token_#{SecureRandom.hex(24)}" },
               headers: @native_app_headers

        assert_response :not_found
        json = JSON.parse(response.body)

        assert_not json["success"]
        assert_includes json["message"], "not found"
      end

      test "DELETE /api/v1/devices - 다른 사용자의 디바이스 비활성화 불가" do
        other_device = devices(:android_device)  # user two의 디바이스

        log_in_as(@user)  # user one으로 로그인

        delete api_v1_devices_url,
               params: { token: other_device.token },
               headers: @native_app_headers

        # 자신의 디바이스가 아니므로 찾을 수 없음
        assert_response :not_found

        other_device.reload
        assert other_device.enabled  # 여전히 활성 상태
      end

      test "DELETE /api/v1/devices - 비로그인 시 401 반환" do
        delete api_v1_devices_url,
               params: { token: @device.token },
               headers: @native_app_headers

        assert_response :unauthorized
      end

      private

      def log_in_as(user)
        post login_url, params: { email: user.email, password: "test1234" }
      end
    end
  end
end
