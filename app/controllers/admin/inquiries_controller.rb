# frozen_string_literal: true

class Admin::InquiriesController < Admin::BaseController
  before_action :set_inquiry, only: [:show, :update]

  def index
    @inquiries = Inquiry.includes(:user, :responded_by).recent

    # 상태 필터
    if params[:status].present?
      @inquiries = @inquiries.where(status: params[:status])
    end

    # 카테고리 필터
    if params[:category].present?
      @inquiries = @inquiries.by_category(params[:category])
    end

    @inquiries = @inquiries.page(params[:page]).per(20)

    # 통계
    @stats = {
      total: Inquiry.count,
      pending: Inquiry.pending.count,
      in_progress: Inquiry.in_progress.count,
      resolved: Inquiry.resolved.count,
      closed: Inquiry.closed.count
    }
  end

  def show
    # 문의 상세
  end

  def update
    new_status = params[:inquiry][:status]
    admin_response = params[:inquiry][:admin_response]

    # 답변이 있으면 답변 + 상태를 함께 처리
    if admin_response.present?
      # 상태가 선택되었으면 해당 상태로, 아니면 기본값 resolved
      status_to_set = new_status.presence || "resolved"
      @inquiry.respond_with_status!(current_user, admin_response, status_to_set)
      # 사용자에게 알림 생성
      create_inquiry_notification(@inquiry)
      redirect_to admin_inquiry_path(@inquiry), notice: "답변이 등록되었습니다."
    elsif new_status.present? && Inquiry::STATUSES.keys.include?(new_status)
      # 답변 없이 상태만 변경
      @inquiry.update_status!(new_status)
      redirect_to admin_inquiry_path(@inquiry), notice: "상태가 변경되었습니다."
    else
      redirect_to admin_inquiry_path(@inquiry), alert: "변경 사항이 없습니다."
    end
  end

  private

  def set_inquiry
    @inquiry = Inquiry.find(params[:id])
  end

  def create_inquiry_notification(inquiry)
    Notification.create(
      recipient: inquiry.user,
      actor: current_user,
      action: "inquiry_response",
      notifiable: inquiry
    )
  rescue StandardError => e
    Rails.logger.error("Failed to create inquiry notification: #{e.message}")
  end
end
