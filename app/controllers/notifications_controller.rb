class NotificationsController < ApplicationController
  before_action :require_login
  before_action :set_notification, only: [ :show, :destroy ]

  # GET /notifications
  # 알림 목록 페이지
  def index
    @notifications = current_user.notifications
                                 .includes(:actor, :notifiable)
                                 .recent
                                 .limit(50)
  end

  # GET /notifications/dropdown
  # 헤더 드롭다운용 최근 알림 (Turbo Frame)
  def dropdown
    @notifications = current_user.notifications
                                 .includes(:actor, :notifiable)
                                 .recent
                                 .limit(10)
    @unread_count = current_user.unread_notifications_count

    render partial: "notifications/dropdown", locals: {
      notifications: @notifications,
      unread_count: @unread_count
    }
  end

  # PATCH /notifications/:id
  # 알림 클릭 시 읽음 처리 후 해당 페이지로 이동
  def show
    @notification.mark_as_read!
    redirect_to @notification.target_path || root_path, allow_other_host: false
  end

  # POST /notifications/mark_all_read
  # 모든 알림 읽음 처리
  def mark_all_read
    current_user.notifications.mark_all_as_read!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("notification-badge", ""),
          turbo_stream.update("notification-dropdown", partial: "notifications/dropdown_list",
            locals: { notifications: current_user.notifications.recent.limit(10) })
        ]
      end
      format.html { redirect_to notifications_path, notice: "모든 알림을 읽음 처리했습니다." }
    end
  end

  # DELETE /notifications/:id
  def destroy
    @notification.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("notification-#{@notification.id}")
      end
      format.html { redirect_to notifications_path, notice: "알림이 삭제되었습니다." }
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
