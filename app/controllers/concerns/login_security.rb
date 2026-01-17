# frozen_string_literal: true

# Login Security Concern
# Handles brute force protection via login attempt tracking and account lockout
#
# Usage:
#   include LoginSecurity
#   After failed login: track_failed_login
#   After successful login: clear_failed_logins
#
module LoginSecurity
  extend ActiveSupport::Concern

  # Security constants
  MAX_FAILED_ATTEMPTS = 5
  LOCKOUT_DURATION = 15.minutes
  ATTEMPT_WINDOW = 10.minutes

  included do
    # Check lockout before processing login
    before_action :check_lockout, only: :create
  end

  private

  # Check if the IP is currently locked out
  def check_lockout
    if ip_locked_out?
      remaining = lockout_remaining_time
      Rails.logger.warn "[SECURITY] Blocked login attempt from locked IP: #{request.remote_ip}"

      respond_to do |format|
        format.html do
          flash[:alert] = "너무 많은 로그인 시도로 계정이 잠겼습니다. #{remaining}분 후에 다시 시도해주세요."
          redirect_to login_path
        end
        format.json do
          render json: {
            error: "Account locked",
            retry_after: remaining * 60
          }, status: :forbidden
        end
      end
    end
  end

  # Track a failed login attempt
  # Called after authentication fails
  def track_failed_login
    key = failed_attempts_key
    count = Rails.cache.increment(key, 1, expires_in: ATTEMPT_WINDOW)

    # First attempt - set initial value if increment returned nil
    if count.nil?
      Rails.cache.write(key, 1, expires_in: ATTEMPT_WINDOW)
      count = 1
    end

    Rails.logger.warn "[SECURITY] Failed login attempt #{count}/#{MAX_FAILED_ATTEMPTS} from IP: #{request.remote_ip}"

    # Check if we should lock out
    if count >= MAX_FAILED_ATTEMPTS
      lockout_ip!
      Rails.logger.warn "[SECURITY] IP locked out after #{count} failed attempts: #{request.remote_ip}"
    end

    count
  end

  # Clear failed login attempts after successful login
  def clear_failed_logins
    Rails.cache.delete(failed_attempts_key)
    Rails.cache.delete(lockout_key)
    Rails.logger.info "[SECURITY] Cleared login attempts for IP: #{request.remote_ip}"
  end

  # Check if the current IP is locked out
  def ip_locked_out?
    Rails.cache.read(lockout_key) == true
  end

  # Get remaining lockout time in minutes
  def lockout_remaining_time
    # Try to get the expiry time from cache metadata
    # Default to full duration if unknown
    begin
      store = Rails.cache
      if store.respond_to?(:redis)
        ttl = store.redis.ttl(lockout_key)
        return (ttl / 60.0).ceil if ttl.positive?
      end
    rescue => e
      Rails.logger.debug "[SECURITY] Could not get TTL: #{e.message}"
    end

    # Default fallback
    LOCKOUT_DURATION.to_i / 60
  end

  # Lock out the current IP
  def lockout_ip!
    Rails.cache.write(lockout_key, true, expires_in: LOCKOUT_DURATION)
  end

  # Cache keys
  def failed_attempts_key
    "login_attempts:#{request.remote_ip}"
  end

  def lockout_key
    "login_lockout:#{request.remote_ip}"
  end
end
