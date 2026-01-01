# frozen_string_literal: true

class ReportsController < ApplicationController
  before_action :require_login
  before_action :set_reportable

  def create
    @report = current_user.reports.build(report_params)
    @report.reportable = @reportable

    if @report.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "report-modal",
            partial: "reports/success"
          )
        end
        format.html { redirect_back fallback_location: root_path, notice: "신고가 접수되었습니다." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "report-form",
            partial: "reports/form",
            locals: { reportable: @reportable, report: @report }
          )
        end
        format.html { redirect_back fallback_location: root_path, alert: @report.errors.full_messages.join(", ") }
      end
    end
  end

  private

  def set_reportable
    reportable_type = params[:reportable_type]
    reportable_id = params[:reportable_id]

    unless Report::VALID_REPORTABLE_TYPES.include?(reportable_type)
      redirect_back fallback_location: root_path, alert: "유효하지 않은 신고 대상입니다."
      return
    end

    @reportable = reportable_type.constantize.find_by(id: reportable_id)

    unless @reportable
      redirect_back fallback_location: root_path, alert: "신고 대상을 찾을 수 없습니다."
      return
    end

    # 자신을 신고할 수 없음
    if reportable_type == "User" && @reportable.id == current_user.id
      redirect_back fallback_location: root_path, alert: "자신을 신고할 수 없습니다."
      return
    end

    # 자신의 게시글을 신고할 수 없음
    if reportable_type == "Post" && @reportable.user_id == current_user.id
      redirect_back fallback_location: root_path, alert: "자신의 게시글은 신고할 수 없습니다."
      return
    end
  end

  def report_params
    params.require(:report).permit(:reason, :description)
  end
end
