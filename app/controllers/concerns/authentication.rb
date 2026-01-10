# frozen_string_literal: true

# 사용자 인증 관련 메서드
#
# 포함 기능:
# - current_user: 현재 로그인한 사용자 조회
# - logged_in?: 로그인 여부 확인
# - log_in/log_out: 세션 기반 로그인/로그아웃
# - remember/forget: Remember Me 쿠키 관리
# - require_login/require_no_login: 접근 제어
module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :logged_in?
  end

  private

  # ==========================================================================
  # Current User
  # ==========================================================================

  # Returns the currently logged-in user (if any)
  # 1. 세션에서 확인 (일반 로그인)
  # 2. 쿠키에서 확인 (Remember Me)
  # 탈퇴한 사용자는 nil 반환 (세션/쿠키 무효화)
  def current_user
    if session[:user_id]
      @current_user ||= User.find_by(id: session[:user_id])
    elsif cookies.encrypted[:user_id]
      # Remember Me: 쿠키 기반 인증
      user = User.find_by(id: cookies.encrypted[:user_id])
      if user&.authenticated?(cookies.encrypted[:remember_token])
        log_in(user)
        @current_user = user
      end
    end

    # 탈퇴한 사용자는 세션/쿠키 무효화
    if @current_user&.deleted?
      forget(@current_user)
      reset_session
      @current_user = nil
    end

    @current_user
  end

  # Returns true if the user is logged in, false otherwise
  def logged_in?
    current_user.present?
  end

  # ==========================================================================
  # Login / Logout
  # ==========================================================================

  # Logs in the given user by storing their id in the session
  # 보안: 로그인 시 세션 ID 재생성 (Session Fixation 방지)
  def log_in(user)
    # 기존 세션의 중요 값들 보존
    return_to = session[:return_to]
    pending_analysis_key = session[:pending_analysis_key]
    pending_input_key = session[:pending_input_key]  # Lazy Registration용

    # 세션 ID 재생성 (Session Fixation Attack 방지)
    reset_session

    # 보존된 값 복원
    session[:return_to] = return_to if return_to.present?
    session[:pending_analysis_key] = pending_analysis_key if pending_analysis_key.present?
    session[:pending_input_key] = pending_input_key if pending_input_key.present?

    # 새 세션에 사용자 ID 저장
    session[:user_id] = user.id
    user.update(last_sign_in_at: Time.current)
  end

  # Logs out the current user by clearing the session and cookies
  # 보안: 로그아웃 시 전체 세션 + 쿠키 삭제
  def log_out
    forget(@current_user) if @current_user
    reset_session  # 세션 완전 삭제 (session.delete보다 안전)
    @current_user = nil
  end

  # ==========================================================================
  # Remember Me
  # ==========================================================================

  # Remember Me: 영구 쿠키 생성 (20년)
  def remember(user)
    user.remember
    cookies.permanent.encrypted[:user_id] = user.id
    cookies.permanent.encrypted[:remember_token] = user.remember_token
  end

  # Remember Me: 쿠키 및 DB 토큰 삭제
  def forget(user)
    user&.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end

  # ==========================================================================
  # Access Control
  # ==========================================================================

  # Before action to require login for protected routes
  def require_login
    unless logged_in?
      # 로그인 후 원래 목적지로 돌아가기 위해 URL 저장 (쿠키 사용 - OAuth에서도 유지됨)
      store_location if request.get?
      flash[:alert] = "로그인이 필요합니다."
      redirect_to login_path
    end
  end

  # Before action to redirect logged-in users (for login/signup pages)
  def require_no_login
    if logged_in?
      flash[:notice] = "이미 로그인되어 있습니다."
      redirect_back_or(community_path)
    end
  end
end
