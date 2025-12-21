class OmniauthCallbacksController < ApplicationController
  # OAuth 콜백은 외부에서 오므로 CSRF 검증 스킵 필요
  skip_before_action :verify_authenticity_token, only: [:create, :failure]

  # OAuth 콜백 처리 (Google, GitHub 공통)
  def create
    auth = request.env["omniauth.auth"]

    unless auth
      Rails.logger.error "OAuth callback received without auth data"
      redirect_to login_path, alert: "로그인에 실패했습니다. 다시 시도해주세요."
      return
    end

    provider_name = auth.provider == "google_oauth2" ? "Google" : "GitHub"

    # 사용자 생성 또는 찾기
    @user = User.from_omniauth(auth)

    if @user.persisted?
      # 세션에 사용자 ID 저장
      session[:user_id] = @user.id

      # 리디렉션 URL 결정 (세션 > 쿠키 > 기본값)
      # omniauth.origin은 외부에서 조작 가능하므로 사용하지 않음 (Open Redirect 방지)
      session_return_to = session.delete(:return_to)
      cookie_return_to = cookies.delete(:return_to)

      Rails.logger.info "[OAuth] session return_to: #{session_return_to.inspect}"
      Rails.logger.info "[OAuth] cookie return_to: #{cookie_return_to.inspect}"

      # URL 검증 후 리디렉션
      redirect_url = validate_redirect_url(session_return_to) ||
                     validate_redirect_url(cookie_return_to) ||
                     community_path

      Rails.logger.info "OAuth login successful: #{provider_name} - User #{@user.id} - Redirecting to: #{redirect_url}"
      flash[:notice] = "#{provider_name} 계정으로 로그인되었습니다!"
      redirect_to redirect_url
    else
      # 사용자 저장 실패 (이메일 중복 등)
      Rails.logger.error "OAuth user creation failed: #{@user.errors.full_messages.join(', ')}"
      redirect_to login_path, alert: "로그인에 실패했습니다. 이미 같은 이메일로 가입된 계정이 있을 수 있습니다."
    end
  end

  # OAuth 실패 시
  def failure
    error_type = params[:message] || "unknown_error"
    Rails.logger.error "OAuth authentication failed: #{error_type}"

    # 세션/쿠키 정리
    session.delete(:return_to)
    cookies.delete(:return_to)

    redirect_to login_path, alert: "로그인에 실패했습니다. 다시 시도해주세요."
  end
end
