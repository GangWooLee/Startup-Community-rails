# frozen_string_literal: true

# Admin Sudo Mode Controller
# Handles re-authentication for sensitive admin operations
#
# Flow:
# 1. Sensitive action redirects here with return URL stored in session
# 2. User enters password
# 3. On success, redirect back to original action
# 4. Sudo mode lasts 15 minutes
#
class Admin::SudoController < Admin::BaseController
  include Admin::SudoMode

  # Skip sudo requirement for this controller (to avoid infinite redirect)
  skip_before_action :require_sudo, raise: false

  # GET /admin/sudo
  # Show password confirmation form
  def show
    @intended_action = session[:sudo_intended_action] || "관리자 작업"
    @return_to = session[:sudo_return_to]
  end

  # POST /admin/sudo
  # Verify password and enable sudo mode
  def create
    if verify_sudo_password(params[:password])
      return_to = session.delete(:sudo_return_to)
      session.delete(:sudo_intended_action)

      flash[:notice] = "재인증되었습니다. 15분간 민감한 작업이 허용됩니다."

      if return_to.present?
        redirect_to return_to
      else
        redirect_to admin_root_path
      end
    else
      @intended_action = session[:sudo_intended_action] || "관리자 작업"
      @return_to = session[:sudo_return_to]

      flash.now[:alert] = "비밀번호가 올바르지 않습니다."
      render :show, status: :unprocessable_entity
    end
  end

  # DELETE /admin/sudo
  # Manually exit sudo mode
  def destroy
    clear_sudo!
    flash[:notice] = "재인증 모드가 종료되었습니다."
    redirect_to admin_root_path
  end
end
