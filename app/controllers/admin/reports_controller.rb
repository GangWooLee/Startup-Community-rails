# frozen_string_literal: true

class Admin::ReportsController < Admin::BaseController
  before_action :set_report, only: [:show, :update]

  def index
    @reports = Report.includes(:reporter, :reportable, :resolved_by).recent

    # 상태 필터
    if params[:status].present?
      @reports = @reports.where(status: params[:status])
    end

    # 신고 대상 유형 필터
    if params[:type].present?
      @reports = @reports.by_type(params[:type])
    end

    @reports = @reports.page(params[:page]).per(20)

    # 통계
    @stats = {
      total: Report.count,
      pending: Report.pending.count,
      reviewed: Report.reviewed.count,
      resolved: Report.resolved.count,
      dismissed: Report.dismissed.count
    }
  end

  def show
    # 신고 대상 정보 로드
    @reportable = @report.reportable
  end

  def update
    new_status = params[:report][:status]
    admin_note = params[:report][:admin_note]

    if Report::STATUSES.keys.include?(new_status)
      @report.resolve!(current_user, new_status, admin_note)
      redirect_to admin_report_path(@report), notice: "신고 상태가 변경되었습니다."
    else
      redirect_to admin_report_path(@report), alert: "유효하지 않은 상태입니다."
    end
  end

  private

  def set_report
    @report = Report.find(params[:id])
  end
end
