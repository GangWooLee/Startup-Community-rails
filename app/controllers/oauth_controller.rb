class OauthController < ApplicationController
  # OAuth 요청 전 return_to URL을 세션에 저장하고 OmniAuth로 리디렉션
  # POST /oauth/:provider
  def passthru
    provider = params[:provider]

    # 허용된 provider만 처리
    unless %w[google_oauth2 github].include?(provider)
      redirect_to login_path, alert: "지원하지 않는 로그인 방식입니다."
      return
    end

    # return_to URL 결정 및 검증
    return_to = validate_return_url(
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

  private

  # URL 검증: 같은 호스트의 상대 경로만 허용
  def validate_return_url(url)
    return nil if url.blank?

    # 상대 경로는 허용
    return url if url.start_with?("/") && !url.start_with?("//")

    # 절대 URL은 같은 호스트만 허용
    begin
      uri = URI.parse(url)
      if uri.host.nil? || uri.host == request.host
        uri.path.presence || "/"
      end
    rescue URI::InvalidURIError
      nil
    end
  end
end
