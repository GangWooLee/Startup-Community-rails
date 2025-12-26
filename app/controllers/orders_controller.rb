# 주문 컨트롤러
# 주문 조회, 결제 완료 페이지, 취소 처리
class OrdersController < ApplicationController
  before_action :require_login
  before_action :set_order, only: [:show, :success, :cancel, :receipt]
  before_action :authorize_order_access, only: [:show, :success, :receipt]
  before_action :authorize_order_cancel, only: [:cancel]

  # GET /orders
  # 주문 목록 (구매 + 판매)
  def index
    @tab = params[:tab] || "purchases"

    case @tab
    when "purchases"
      @orders = current_user.orders.includes(:post, :seller).recent
    when "sales"
      @orders = current_user.sales.includes(:post, :user).recent
    else
      @orders = current_user.orders.includes(:post, :seller).recent
    end

    @orders = @orders.page(params[:page]).per(20) if @orders.respond_to?(:page)
  end

  # GET /orders/:id
  # 주문 상세
  def show
    @payment = @order.successful_payment || @order.payments.order(created_at: :desc).first
  end

  # GET /orders/:id/success
  # 결제 완료 페이지
  def success
    @payment = @order.successful_payment
  end

  # GET /orders/:id/receipt
  # 영수증 페이지
  def receipt
    @payment = @order.successful_payment

    unless @payment&.done?
      redirect_to order_path(@order), alert: "결제 완료된 주문만 영수증을 확인할 수 있습니다."
    end
  end

  # POST /orders/:id/cancel
  # 주문 취소
  def cancel
    if @order.can_cancel?
      # 결제 완료 상태면 토스페이먼츠 취소 API 호출
      if @order.paid? && @order.successful_payment.present?
        service = TossPayments::CancelService.new
        result = service.cancel_payment(@order.successful_payment, reason: cancel_reason)

        unless result.success?
          redirect_to order_path(@order), alert: "결제 취소 실패: #{result.error&.message}"
          return
        end
      end

      @order.mark_as_cancelled!
      redirect_to orders_path, notice: "주문이 취소되었습니다."
    else
      redirect_to order_path(@order), alert: "취소할 수 없는 주문입니다."
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to orders_path, alert: "주문을 찾을 수 없습니다."
  end

  # 주문 조회 권한 확인 (구매자 또는 판매자)
  def authorize_order_access
    unless @order.user_id == current_user.id || @order.seller_id == current_user.id
      redirect_to orders_path, alert: "접근 권한이 없습니다."
    end
  end

  # 주문 취소 권한 확인 (구매자만)
  def authorize_order_cancel
    unless @order.user_id == current_user.id
      redirect_to orders_path, alert: "취소 권한이 없습니다."
    end
  end

  def cancel_reason
    params[:reason].presence || "사용자 요청에 의한 취소"
  end
end
