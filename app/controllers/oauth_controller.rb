# frozen_string_literal: true

class OauthController < ApplicationController
  include UserAgentHelper
  include SessionRedirect  # Phase 3.1: URL 검증 로직 통합

  # OAuth 요청 전 return_to URL을 세션에 저장하고 OmniAuth로 리디렉션
  # POST /oauth/:provider
  def passthru
    provider = params[:provider]

    # 허용된 provider만 처리
    unless %w[google_oauth2 github].include?(provider)
      redirect_to login_path, alert: "지원하지 않는 로그인 방식입니다."
      return
    end

    # WebView에서 Google OAuth 시도 시 경고 페이지로 리다이렉트
    # Google은 보안 이유로 WebView에서 OAuth를 차단함 (403 disallowed_useragent)
    if provider == "google_oauth2" && in_app_browser?
      session[:oauth_return_to] = validate_redirect_url(
        params[:origin].presence || cookies[:return_to].presence || session[:return_to].presence
      )
      redirect_to oauth_webview_warning_path
      return
    end

    # return_to URL 결정 및 검증
    return_to = validate_redirect_url(
      params[:origin].presence || cookies[:return_to].presence || session[:return_to].presence
    )

    if return_to.present?
      # 세션에 저장 (OAuth 외부 리디렉션 후에도 유지)
      session[:return_to] = return_to
      Rails.logger.info "[OAuth Passthru] Saved return_to to session: #{return_to}"
    end

    # OmniAuth는 POST 요청을 기대하므로 폼으로 리디렉션
    # (OmniAuth.config.allowed_request_methods = [:post] 설정됨)
    redirect_to "/auth/#{provider}", allow_other_host: true
  end

  # WebView 감지 시 표시되는 경고 페이지
  # GET /oauth/webview_warning
  def webview_warning
    # 이미 일반 브라우저에서 접속한 경우 로그인 페이지로
    unless in_app_browser?
      redirect_to login_path
      return
    end

    @detected_app = detected_app_name
    @login_url = login_url
    @is_ios = ios_device?
    @is_android = android_device?
    @is_kakao = kakao_in_app_browser?

    # 카카오톡 외부 브라우저 열기 URL 생성
    if @is_kakao
      @kakao_external_url = "kakaotalk://web/openExternal?url=#{CGI.escape(@login_url)}"
    end
  end
end
