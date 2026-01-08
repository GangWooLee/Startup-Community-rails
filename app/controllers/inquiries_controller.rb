# frozen_string_literal: true

class InquiriesController < ApplicationController
  before_action :require_login
  before_action :set_inquiry, only: [ :show ]

  def index
    @filter = params[:filter] || "all"
    @search = params[:q]
    @inquiries = current_user.inquiries.order(created_at: :desc)

    # 검색 필터 적용
    if @search.present?
      search_term = "%#{@search}%"
      @inquiries = @inquiries.where(
        "title LIKE ? OR content LIKE ?",
        search_term, search_term
      )
    end

    # 상태 필터 적용
    case @filter
    when "pending"
      @inquiries = @inquiries.where(status: [ :pending, :in_progress ])
    when "answered"
      @inquiries = @inquiries.where(status: [ :resolved, :closed ])
    end

    @inquiries = @inquiries.page(params[:page]).per(10)
  end

  def new
    @inquiry = current_user.inquiries.build
  end

  def create
    @inquiry = current_user.inquiries.build(inquiry_params)

    if @inquiry.save
      redirect_to inquiries_path, notice: "문의가 등록되었습니다. 답변은 알림으로 전달됩니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # 본인의 문의만 볼 수 있음
    unless @inquiry.user_id == current_user.id
      redirect_to inquiries_path, alert: "접근 권한이 없습니다."
    end
  end

  private

  def set_inquiry
    @inquiry = Inquiry.find(params[:id])
  end

  def inquiry_params
    params.require(:inquiry).permit(:category, :title, :content, :is_private)
  end
end
