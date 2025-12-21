class OauthController < ApplicationController
  skip_before_action :verify_authenticity_token

  # OAuth 요청 전 return_to URL을 세션에 저장하고 OmniAuth로 리디렉션
  # POST /oauth/:provider
  def passthru
    provider = params[:provider]

    # return_to URL 결정 (우선순위: origin 파라미터 > 쿠키 > 세션)
    return_to = params[:origin].presence || cookies[:return_to].presence || session[:return_to].presence

    if return_to.present?
      # 세션에 저장 (OAuth 외부 리디렉션 후에도 유지)
      session[:return_to] = return_to
      Rails.logger.info "[OAuth Passthru] Saved return_to to session: #{return_to}"

      # OmniAuth에 origin 파라미터로 전달 (omniauth.origin에 설정됨)
      redirect_to "/auth/#{provider}?origin=#{CGI.escape(return_to)}", allow_other_host: true
    else
      Rails.logger.info "[OAuth Passthru] No return_to found, redirecting without origin"
      redirect_to "/auth/#{provider}", allow_other_host: true
    end
  end
end
