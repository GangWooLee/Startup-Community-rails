class OauthTermsController < ApplicationController
  # 로그인 전 상태이므로 require_login 스킵
  skip_before_action :require_login, if: -> { respond_to?(:require_login, true) }

  # GET /oauth/terms
  def show
    @user = find_pending_user
    unless @user
      redirect_to login_path, alert: "세션이 만료되었습니다. 다시 로그인해주세요."
      return
    end

    # 이미 약관에 동의한 경우 바로 로그인 처리
    if @user.all_terms_accepted?
      complete_oauth_login
    end
  end

  # POST /oauth/terms/accept
  def accept
    @user = find_pending_user
    unless @user
      redirect_to login_path, alert: "세션이 만료되었습니다. 다시 로그인해주세요."
      return
    end

    # 약관 동의 검증 (3개 모두 체크 필수)
    unless terms_all_agreed?
      flash.now[:alert] = "이용약관, 개인정보 처리방침, 커뮤니티 가이드라인에 모두 동의해주세요."
      render :show, status: :unprocessable_entity
      return
    end

    # 약관 동의 저장
    @user.accept_terms!
    Rails.logger.info "OAuth terms accepted: User #{@user.id}"

    # 로그인 완료 처리
    complete_oauth_login
  end

  private

  def find_pending_user
    user_id = session[:pending_oauth_user_id]
    return nil unless user_id
    User.find_by(id: user_id)
  end

  def terms_all_agreed?
    params[:terms_agreement] == "1" &&
    params[:privacy_agreement] == "1" &&
    params[:guidelines_agreement] == "1"
  end

  def complete_oauth_login
    # 세션 정리
    session.delete(:pending_oauth_user_id)
    return_to = session.delete(:oauth_return_to)

    # 로그인 처리
    log_in(@user)

    # 리디렉션 (원래 가려던 곳 또는 커뮤니티)
    flash[:notice] = "환영합니다! 회원가입이 완료되었습니다."
    redirect_to return_to.presence || community_path
  end
end
