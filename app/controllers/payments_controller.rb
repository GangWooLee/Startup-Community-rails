# frozen_string_literal: true

# 결제 컨트롤러
# 토스페이먼츠 결제 위젯 페이지 및 결제 처리
# 지원 방식:
# 1. Post 기반 결제: GET /payments/new?post_id=:id
# 2. 채팅 거래 제안 기반 결제: GET /payments/new?offer_message_id=:id
require "ostruct"

class PaymentsController < ApplicationController
  # 웹훅은 외부 서비스에서 호출하므로 인증/CSRF 제외
  skip_before_action :verify_authenticity_token, only: [ :webhook ]

  before_action :require_login, except: [ :webhook ]
  before_action :set_payment_context, only: [ :new, :create ]
  before_action :validate_payment_eligibility, only: [ :new, :create ]

  # ==========================================================================
  # 결제 위젯 & 주문 생성
  # ==========================================================================

  # GET /payments/new?post_id=:id 또는 GET /payments/new?offer_message_id=:id
  # 결제 위젯 페이지 렌더링
  def new
    result = find_or_create_order

    if result.success?
      @order = result.order
      @payment = result.payment
      @toss_client_key = toss_client_key
      @customer_key = current_user.toss_customer_key
    else
      redirect_back_or_root(result.errors.join(", "))
    end
  end

  # POST /payments
  # 주문 및 결제 레코드 생성 (AJAX 요청용)
  def create
    result = find_or_create_order

    if result.success?
      render json: {
        success: true,
        order_id: result.payment.toss_order_id,
        order_name: result.order.title,
        amount: result.order.amount,
        customer_key: current_user.toss_customer_key,
        customer_name: current_user.name,
        customer_email: current_user.email
      }
    else
      render json: { success: false, errors: result.errors }, status: :unprocessable_entity
    end
  end

  # ==========================================================================
  # 결제 결과 처리
  # ==========================================================================

  # GET /payments/success
  # 토스페이먼츠에서 결제 완료 후 리다이렉트
  # 중복 승인 방지 (idempotency): 이미 완료된 결제는 API 호출 생략
  def success
    payment_key = params[:paymentKey]
    order_id = params[:orderId]
    amount = params[:amount].to_i

    # 1. 기존 결제 확인 - 이미 완료된 경우 바로 리다이렉트
    existing_payment = Payment.find_by_toss_order_id(order_id)

    if existing_payment&.done?
      handle_already_approved_payment(existing_payment)
      return
    end

    # 2. 결제 승인 처리 (첫 요청)
    result = TossPayments::ApproveService.new.call(
      payment_key: payment_key,
      order_id: order_id,
      amount: amount
    )

    if result.success?
      handle_successful_approval(order_id)
    else
      handle_failed_approval(result, order_id)
    end
  end

  # GET /payments/fail
  # 토스페이먼츠에서 결제 실패 시 리다이렉트
  def fail
    @error_code = params[:code]
    @error_message = params[:message]
    @order_id = params[:orderId]

    if @order_id.present?
      payment = Payment.find_by_toss_order_id(@order_id)
      payment&.mark_as_failed!(code: @error_code, message: @error_message)
    end

    Rails.logger.warn "[PaymentsController#fail] Payment failed: #{@error_code} - #{@error_message}"
  end

  # ==========================================================================
  # 웹훅
  # ==========================================================================

  # POST /payments/webhook
  # 토스페이먼츠 웹훅 (결제 상태 변경 알림)
  # 보안: HMAC-SHA256 서명 검증 (Production 필수)
  def webhook
    raw_body = request.body.read
    signature = request.headers["TossPayments-Signature"]

    # 서명 검증
    verifier = Payments::WebhookSignatureVerifier.new(raw_body, signature)
    unless verifier.valid?
      head :unauthorized
      return
    end

    payload = JSON.parse(raw_body, symbolize_names: true)

    # 방어 코드: payload 타입 검증
    unless payload.is_a?(Hash)
      Rails.logger.error "[PaymentsController#webhook] Unexpected payload format: #{payload.class}"
      head :bad_request
      return
    end

    # 웹훅 처리 위임
    Payments::WebhookHandler.call(payload)

    head :ok
  rescue JSON::ParserError => e
    Rails.logger.error "[PaymentsController#webhook] JSON parse error: #{e.message}"
    head :bad_request
  end

  private

  # ==========================================================================
  # 결제 컨텍스트 설정
  # ==========================================================================

  def set_payment_context
    if params[:post_id].present?
      set_post_context
    elsif params[:offer_message_id].present?
      set_offer_context
    else
      redirect_to root_path, alert: "결제 대상을 찾을 수 없습니다."
    end
  end

  def set_post_context
    @post = Post.find_by(id: params[:post_id])
    redirect_to root_path, alert: "게시글을 찾을 수 없습니다." unless @post
  end

  def set_offer_context
    @offer_message = Message.find_by(id: params[:offer_message_id])

    unless @offer_message&.offer_card?
      redirect_to root_path, alert: "거래 제안을 찾을 수 없습니다."
      return
    end

    @chat_room = @offer_message.chat_room

    unless @chat_room.users.include?(current_user)
      redirect_to root_path, alert: "접근 권한이 없습니다."
      return
    end

    if @offer_message.sender == current_user
      redirect_to chat_room_path(@chat_room), alert: "본인이 보낸 제안은 결제할 수 없습니다."
    end
  end

  # ==========================================================================
  # Validation & Order Creation
  # ==========================================================================

  def validate_payment_eligibility
    result = Payments::EligibilityValidator.new(
      user: current_user,
      post: @post,
      offer_message: @offer_message,
      chat_room: @chat_room
    ).call

    return if result.success?

    path_info = result.redirect_path
    redirect_to send(path_info.first, *path_info[1..]), alert: result.alert_message
  end

  def find_or_create_order
    if @post.present?
      find_or_create_post_order
    elsif @offer_message.present?
      find_or_create_offer_order
    end
  end

  def find_or_create_post_order
    existing_order = current_user.orders.pending.find_by(post: @post)

    if existing_order
      payment = existing_order.payments.pending.first || create_new_payment(existing_order)
      return OpenStruct.new(success?: true, order: existing_order, payment: payment, errors: [])
    end

    Orders::CreateService.new(user: current_user, post: @post).call
  end

  def find_or_create_offer_order
    existing_order = current_user.orders.pending.find_by(offer_message: @offer_message)

    if existing_order
      payment = existing_order.payments.pending.first || create_new_payment(existing_order)
      return OpenStruct.new(success?: true, order: existing_order, payment: payment, errors: [])
    end

    Orders::CreateService.new(
      user: current_user,
      chat_room: @chat_room,
      offer_message: @offer_message
    ).call
  end

  def create_new_payment(order)
    Payment.create!(order: order, user: current_user, amount: order.amount)
  end

  # ==========================================================================
  # Success/Fail Handlers
  # ==========================================================================

  def handle_already_approved_payment(payment)
    Rails.logger.info "[PaymentsController#success] Payment already approved: #{payment.toss_order_id}"
    track_ga4_event("payment_complete", { order_id: payment.order_id, amount: payment.amount })
    redirect_to success_order_path(payment.order), notice: "결제가 완료되었습니다!"
  end

  def handle_successful_approval(order_id)
    @payment = Payment.find_by_toss_order_id(order_id)
    @order = @payment&.order

    if @order
      track_ga4_event("payment_complete", { order_id: @order.id, amount: @payment&.amount })
      redirect_to success_order_path(@order), notice: "결제가 완료되었습니다!"
    else
      redirect_to root_path, alert: "주문 정보를 찾을 수 없습니다."
    end
  end

  def handle_failed_approval(result, order_id)
    Rails.logger.error "[PaymentsController#success] Payment approval failed: #{result.error&.message}"
    redirect_to fail_payments_path(
      code: result.error&.code,
      message: result.error&.message,
      orderId: order_id
    )
  end

  def redirect_back_or_root(message)
    if @post.present?
      redirect_to post_path(@post), alert: message
    elsif @chat_room.present?
      redirect_to chat_room_path(@chat_room), alert: message
    else
      redirect_to root_path, alert: message
    end
  end

  # ==========================================================================
  # Configuration
  # ==========================================================================

  def toss_client_key
    key = Rails.application.credentials.dig(:toss, :client_key)

    if key.present?
      key
    elsif Rails.env.production?
      raise "TossPayments client_key가 설정되지 않았습니다. Rails credentials에 toss.client_key를 추가하세요."
    else
      Rails.logger.warn "[PaymentsController] Using test client key (development only)"
      "test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm"
    end
  end
end
