# frozen_string_literal: true

# Admin Sudo Mode
# Requires re-authentication for sensitive actions
#
# Similar to GitHub's Sudo mode where entering your password
# grants temporary elevated access for a short period.
#
# Usage:
#   class Admin::UsersController < Admin::BaseController
#     include Admin::SudoMode
#
#     # Option 1: Require sudo for specific actions
#     before_action :require_sudo, only: [:destroy, :change_role]
#
#     # Option 2: Check sudo status manually
#     def destroy_all
#       return unless ensure_sudo_mode
#       # ... dangerous operation
#     end
#   end
#
module Admin
  module SudoMode
    extend ActiveSupport::Concern

    # Sudo mode duration (15 minutes)
    SUDO_DURATION = 15.minutes

    included do
      helper_method :sudo_mode_active?
    end

    private

    # Check if sudo mode is currently active
    def sudo_mode_active?
      return false unless session[:sudo_confirmed_at]

      Time.at(session[:sudo_confirmed_at]) > SUDO_DURATION.ago
    end

    # Remaining sudo time in minutes
    def sudo_remaining_minutes
      return 0 unless sudo_mode_active?

      confirmed_at = Time.at(session[:sudo_confirmed_at])
      remaining = SUDO_DURATION - (Time.current - confirmed_at)
      (remaining / 60).ceil
    end

    # Confirm sudo mode (called after password verification)
    def confirm_sudo!
      session[:sudo_confirmed_at] = Time.current.to_i
      Rails.logger.info "[SECURITY] Sudo mode confirmed for admin #{current_user&.id}"
    end

    # Clear sudo mode
    def clear_sudo!
      session.delete(:sudo_confirmed_at)
    end

    # Before action to require sudo for sensitive operations
    # Stores the intended action and redirects to confirmation if needed
    def require_sudo
      return if sudo_mode_active?

      # Store the original request for redirect after confirmation
      session[:sudo_return_to] = request.fullpath
      session[:sudo_intended_action] = "#{controller_name}##{action_name}"

      Rails.logger.info "[SECURITY] Sudo required for #{session[:sudo_intended_action]} by admin #{current_user&.id}"

      respond_to do |format|
        format.html { redirect_to admin_sudo_path }
        format.json { render json: { error: "Sudo mode required", sudo_url: admin_sudo_path }, status: :forbidden }
        format.turbo_stream { redirect_to admin_sudo_path }
      end
    end

    # Alternative: Check and return boolean (for use in action body)
    def ensure_sudo_mode
      return true if sudo_mode_active?

      require_sudo
      false
    end

    # Verify password and enable sudo mode
    # Returns true if verification successful
    def verify_sudo_password(password)
      return false if current_user.nil? || password.blank?

      if current_user.authenticate(password)
        confirm_sudo!

        # Log the sudo confirmation
        AdminViewLog.log_action(
          admin: current_user,
          action: "sudo_mode_enabled",
          target: current_user,
          reason: "Sudo mode enabled for sensitive operations",
          request: request
        )

        true
      else
        Rails.logger.warn "[SECURITY] Failed sudo attempt for admin #{current_user.id}"
        false
      end
    end
  end
end
