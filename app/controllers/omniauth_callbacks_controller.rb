class OmniauthCallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :failure]

  # OAuth 콜백 처리 (Google, GitHub 공통)
  def create
    auth = request.env["omniauth.auth"]
    provider_name = auth.provider == "google_oauth2" ? "Google" : "GitHub"

    # 사용자 생성 또는 찾기
    @user = User.from_omniauth(auth)

    if @user.persisted?
      # 세션에 사용자 ID 저장
      session[:user_id] = @user.id

      # origin 파라미터 또는 쿠키에서 리디렉션 URL 가져오기
      origin_url = request.env["omniauth.origin"] || cookies.delete(:return_to)
      redirect_url = origin_url.presence || community_path

      Rails.logger.info "OAuth login successful: #{provider_name} - User #{@user.id} - Redirecting to: #{redirect_url}"
      redirect_to redirect_url
      flash[:notice] = "#{provider_name} 계정으로 로그인되었습니다!"
    else
      # 사용자 저장 실패 (이메일 중복 등)
      Rails.logger.error "OAuth user creation failed: #{@user.errors.full_messages.join(', ')}"
      redirect_to login_path, alert: "로그인에 실패했습니다. 이미 같은 이메일로 가입된 계정이 있을 수 있습니다."
    end
  end

  # OAuth 실패 시
  def failure
    Rails.logger.error "OAuth authentication failed: #{params[:message]}"
    redirect_to login_path, alert: "로그인에 실패했습니다. 다시 시도해주세요."
  end
end
