# frozen_string_literal: true

# API 인증 Concern
#
# Hotwire Native 앱용 API 컨트롤러에서 공통으로 사용하는 인증 메서드를 제공합니다.
#
# @example 사용법
#   class Api::V1::SomeController < ApplicationController
#     include Api::Authenticatable
#
#     before_action :require_hotwire_native_app
#     before_action :require_login
#   end
#
module Api
  module Authenticatable
    extend ActiveSupport::Concern

    private

    # Hotwire Native 앱에서만 접근 가능
    # User-Agent에 "Turbo Native" 포함 여부로 판단
    def require_hotwire_native_app
      return if hotwire_native_app?

      render json: {
        success: false,
        message: "This API is only available for native apps"
      }, status: :forbidden
    end

    # 로그인 필수 (세션 기반)
    # WebView가 Rails 세션 쿠키를 공유하므로 기존 인증 방식 사용
    def require_login
      return if logged_in?

      render json: {
        success: false,
        message: "Authentication required"
      }, status: :unauthorized
    end
  end
end
