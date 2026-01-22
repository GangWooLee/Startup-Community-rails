# frozen_string_literal: true

# 디바이스 등록 API (Push Notification용)
#
# Hotwire Native 앱에서 FCM 토큰을 등록/해제합니다.
# 웹뷰 세션을 통해 인증하므로 별도 API 토큰 불필요.
#
# @example 디바이스 등록
#   POST /api/v1/devices
#   { "platform": "ios", "token": "fcm_token", "device_name": "iPhone 15" }
#
# @example 디바이스 해제 (로그아웃 시)
#   DELETE /api/v1/devices
#   { "token": "fcm_token" }
#
module Api
  module V1
    class DevicesController < ApplicationController
      # API 전용 설정
      skip_before_action :verify_authenticity_token
      before_action :require_login
      before_action :require_hotwire_native_app

      # POST /api/v1/devices
      # 디바이스 등록 또는 업데이트
      def create
        device = Device.register(
          user: current_user,
          platform: device_params[:platform],
          token: device_params[:token],
          device_name: device_params[:device_name],
          app_version: device_params[:app_version]
        )

        if device.persisted?
          render json: {
            success: true,
            device: device_response(device)
          }, status: :created
        else
          render json: {
            success: false,
            errors: device.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/devices
      # 디바이스 비활성화 (토큰 기반)
      def destroy
        device = current_user.devices.find_by(token: params[:token])

        if device
          device.disable!
          render json: { success: true, message: "Device disabled" }
        else
          render json: { success: false, message: "Device not found" }, status: :not_found
        end
      end

      private

      def device_params
        params.permit(:platform, :token, :device_name, :app_version)
      end

      def device_response(device)
        {
          id: device.id,
          platform: device.platform,
          enabled: device.enabled,
          created_at: device.created_at.iso8601
        }
      end

      # Hotwire Native 앱에서만 접근 가능
      def require_hotwire_native_app
        return if hotwire_native_app?

        render json: {
          success: false,
          message: "This API is only available for native apps"
        }, status: :forbidden
      end

      # 로그인 필수 (세션 기반)
      def require_login
        return if logged_in?

        render json: {
          success: false,
          message: "Authentication required"
        }, status: :unauthorized
      end
    end
  end
end
