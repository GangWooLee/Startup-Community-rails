class SettingsController < ApplicationController
  before_action :require_login
  before_action :hide_floating_button

  def show
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(settings_params)
      respond_to do |format|
        format.html { redirect_to settings_path, notice: "설정이 저장되었습니다." }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "notification-toggle",
            partial: "settings/notification_toggle",
            locals: { user: @user }
          )
        end
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:user).permit(:notifications_enabled)
  end
end
