class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # 페이지네이션 상수
  POSTS_PER_PAGE = 50          # 메인 피드 글 수
  PROFILE_POSTS_LIMIT = 10     # 프로필 페이지 글 수

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Authentication helpers
  helper_method :current_user, :logged_in?

  private

  # Returns the currently logged-in user (if any)
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # Returns true if the user is logged in, false otherwise
  def logged_in?
    current_user.present?
  end

  # Logs in the given user by storing their id in the session
  def log_in(user)
    session[:user_id] = user.id
    user.update(last_sign_in_at: Time.current)
  end

  # Logs out the current user by clearing the session
  def log_out
    session.delete(:user_id)
    @current_user = nil
  end

  # Before action to require login for protected routes
  def require_login
    unless logged_in?
      # 로그인 후 원래 목적지로 돌아가기 위해 URL 저장
      session[:return_to] = request.original_url if request.get?
      flash[:alert] = "로그인이 필요합니다."
      redirect_to login_path
    end
  end

  # 저장된 URL로 리디렉션하거나 기본 경로로 이동
  def redirect_back_or(default)
    redirect_to(session.delete(:return_to) || default)
  end

  # Before action to redirect logged-in users (for login/signup pages)
  def require_no_login
    if logged_in?
      flash[:notice] = "이미 로그인되어 있습니다."
      redirect_to root_path
    end
  end

  # 플로팅 글쓰기 버튼 숨김 (글 작성/수정 등 특정 페이지에서 사용)
  def hide_floating_button
    @hide_floating_button = true
  end
end
