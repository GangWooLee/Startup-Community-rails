# frozen_string_literal: true

# Admin Audit Logging Concern
# Provides convenient methods for logging admin actions
#
# Usage:
#   include Admin::AuditLoggable
#
#   def destroy_post
#     @post = Post.find(params[:id])
#     audit_log(:delete_post, @post, "정책 위반")
#     @post.destroy
#   end
#
module Admin
  module AuditLoggable
    extend ActiveSupport::Concern

    private

    # Log an admin action
    # @param action [Symbol, String] Action type (see AdminViewLog::ACTIONS)
    # @param target [ActiveRecord::Base] Target record
    # @param reason [String] Reason for the action (min 5 chars)
    # @param metadata [Hash] Additional metadata to include
    def audit_log(action, target, reason, metadata: {})
      AdminViewLog.log_action(
        admin: current_user,
        action: action,
        target: target,
        reason: reason,
        request: request,
        metadata: metadata
      )
    end

    # Log action with auto-generated reason based on controller/action
    # @param target [ActiveRecord::Base] Target record
    # @param custom_reason [String, nil] Optional custom reason
    def auto_audit_log(target, custom_reason = nil)
      action = derive_audit_action
      reason = custom_reason || generate_default_reason(target)

      audit_log(action, target, reason)
    end

    # Derive audit action from controller action name
    def derive_audit_action
      case action_name
      when "destroy", "delete"
        determine_delete_action
      when "force_logout"
        "force_logout_session"
      when "force_logout_all"
        "force_logout_all_sessions"
      when "export"
        "export_data"
      when "reveal", "show_personal"
        "reveal_personal_info"
      when "approve"
        "approve_report"
      when "dismiss", "reject"
        "dismiss_report"
      when "hide"
        determine_hide_action
      when "restore"
        determine_restore_action
      when "update_role", "change_role"
        "change_user_role"
      else
        # Default: use controller + action
        "#{controller_name.singularize}_#{action_name}"
      end
    end

    # Generate default reason based on target
    def generate_default_reason(target)
      target_desc = case target
      when User
                      "User##{target.id} (#{target.name})"
      when Post
                      "Post##{target.id} (#{target.title.truncate(20)})"
      when Comment
                      "Comment##{target.id}"
      when Report
                      "Report##{target.id}"
      else
                      "#{target.class.name}##{target.id}"
      end

      "#{action_name.humanize} - #{target_desc}"
    end

    # Determine delete action based on target type
    def determine_delete_action
      case controller_name
      when "posts" then "delete_post"
      when "comments" then "delete_comment"
      when "users" then "delete_user"
      when "api_keys" then "delete_api_key"
      else "delete_#{controller_name.singularize}"
      end
    end

    # Determine hide action based on target type
    def determine_hide_action
      case controller_name
      when "posts" then "hide_post"
      when "comments" then "hide_comment"
      else "hide_#{controller_name.singularize}"
      end
    end

    # Determine restore action based on target type
    def determine_restore_action
      case controller_name
      when "posts" then "restore_post"
      when "users" then "restore_user"
      else "restore_#{controller_name.singularize}"
      end
    end

    # Check if current action is sensitive (requires re-authentication)
    def sensitive_action?
      AdminViewLog.sensitive_action?(derive_audit_action)
    end

    # Log and return true if this is a sensitive action
    # Can be used in before_action to check
    def check_sensitive_action
      if sensitive_action?
        Rails.logger.info "[SECURITY] Sensitive admin action: #{derive_audit_action} by #{current_user&.email}"
      end
      true
    end
  end
end
