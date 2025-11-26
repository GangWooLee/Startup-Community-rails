class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

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
      flash[:alert] = "로그인이 필요합니다."
      redirect_to login_path
    end
  end

  # Before action to redirect logged-in users (for login/signup pages)
  def require_no_login
    if logged_in?
      flash[:notice] = "이미 로그인되어 있습니다."
      redirect_to root_path
    end
  end
end
