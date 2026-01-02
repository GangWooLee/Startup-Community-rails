# 결제 컨트롤러
# 토스페이먼츠 결제 위젯 페이지 및 결제 처리
# 지원 방식:
# 1. Post 기반 결제: GET /payments/new?post_id=:id
# 2. 채팅 거래 제안 기반 결제: GET /payments/new?offer_message_id=:id
require "ostruct"

class PaymentsController < ApplicationController
  # 웹훅은 외부 서비스에서 호출하므로 인증/CSRF 제외
  skip_before_action :verify_authenticity_token, only: [:webhook]

  before_action :require_login, except: [:webhook]
  before_action :set_payment_context, only: [:new, :create]
  before_action :validate_payment_eligibility, only: [:new, :create]

  # GET /payments/new?post_id=:id 또는 GET /payments/new?offer_message_id=:id
  # 결제 위젯 페이지 렌더링
  def new
    # 기존 주문이 있으면 재사용, 없으면 새로 생성
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
      render json: {
        success: false,
        errors: result.errors
      }, status: :unprocessable_entity
    end
  end

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
      # 이미 승인 완료된 결제 - API 호출 생략
      Rails.logger.info "[PaymentsController#success] Payment already approved: #{order_id}"
      redirect_to success_order_path(existing_payment.order), notice: "결제가 완료되었습니다!"
      return
    end

    # 2. 결제 승인 처리 (첫 요청)
    service = TossPayments::ApproveService.new
    result = service.call(
      payment_key: payment_key,
      order_id: order_id,
      amount: amount
    )

    if result.success?
      @payment = Payment.find_by_toss_order_id(order_id)
      @order = @payment&.order

      if @order
        redirect_to success_order_path(@order), notice: "결제가 완료되었습니다!"
      else
        redirect_to root_path, alert: "주문 정보를 찾을 수 없습니다."
      end
    else
      Rails.logger.error "[PaymentsController#success] Payment approval failed: #{result.error&.message}"
      redirect_to payments_fail_path(
        code: result.error&.code,
        message: result.error&.message,
        orderId: order_id
      )
    end
  end

  # GET /payments/fail
  # 토스페이먼츠에서 결제 실패 시 리다이렉트
  def fail
    @error_code = params[:code]
    @error_message = params[:message]
    @order_id = params[:orderId]

    # 결제 실패 기록
    if @order_id.present?
      payment = Payment.find_by_toss_order_id(@order_id)
      payment&.mark_as_failed!(code: @error_code, message: @error_message)
    end

    Rails.logger.warn "[PaymentsController#fail] Payment failed: #{@error_code} - #{@error_message}"
  end

  # POST /payments/webhook
  # 토스페이먼츠 웹훅 (결제 상태 변경 알림)
  # 보안: HMAC-SHA256 서명 검증 (Production 필수)
  def webhook
    raw_body = request.body.read
    signature = request.headers["TossPayments-Signature"]

    # 서명 검증 - Production에서는 필수
    unless verify_webhook_with_signature(raw_body, signature)
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

    event_type = payload[:eventType]

    Rails.logger.info "[PaymentsController#webhook] Received: #{event_type}"

    case event_type
    when "PAYMENT_STATUS_CHANGED"
      handle_payment_status_change(payload)
    when "DEPOSIT_CALLBACK"
      handle_virtual_account_deposit(payload)
    end

    head :ok
  rescue JSON::ParserError => e
    Rails.logger.error "[PaymentsController#webhook] JSON parse error: #{e.message}"
    head :bad_request
  end

  private

  # 결제 컨텍스트 설정 (Post 또는 채팅 거래 제안)
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

    unless @post
      redirect_to root_path, alert: "게시글을 찾을 수 없습니다."
    end
  end

  def set_offer_context
    @offer_message = Message.find_by(id: params[:offer_message_id])

    unless @offer_message&.offer_card?
      redirect_to root_path, alert: "거래 제안을 찾을 수 없습니다."
      return
    end

    @chat_room = @offer_message.chat_room

    # 채팅방 참여자만 결제 가능
    unless @chat_room.users.include?(current_user)
      redirect_to root_path, alert: "접근 권한이 없습니다."
      return
    end

    # 제안을 보낸 사람이 아닌 상대방만 결제 가능
    if @offer_message.sender == current_user
      redirect_to chat_room_path(@chat_room), alert: "본인이 보낸 제안은 결제할 수 없습니다."
      return
    end
  end

  # 결제 가능 여부 검증
  def validate_payment_eligibility
    if @post.present?
      validate_post_payment_eligibility
    elsif @offer_message.present?
      validate_offer_payment_eligibility
    end
  end

  def validate_post_payment_eligibility
    unless @post.outsourcing?
      redirect_to post_path(@post), alert: "외주 글만 결제할 수 있습니다."
      return
    end

    unless @post.payable?
      redirect_to post_path(@post), alert: "가격이 설정되지 않은 글입니다."
      return
    end

    if @post.owned_by?(current_user)
      redirect_to post_path(@post), alert: "본인의 글은 결제할 수 없습니다."
      return
    end

    if @post.paid_by?(current_user)
      redirect_to post_path(@post), alert: "이미 결제한 글입니다."
      return
    end
  end

  def validate_offer_payment_eligibility
    offer_data = @offer_message.offer_data

    unless offer_data.present?
      redirect_to chat_room_path(@chat_room), alert: "거래 제안 정보가 올바르지 않습니다."
      return
    end

    # 이미 결제된 제안인지 확인
    if @offer_message.offer_paid? || @offer_message.offer_completed?
      redirect_to chat_room_path(@chat_room), alert: "이미 결제된 거래입니다."
      return
    end

    # 취소된 제안인지 확인
    if @offer_message.offer_cancelled?
      redirect_to chat_room_path(@chat_room), alert: "취소된 거래 제안입니다."
      return
    end

    # 금액 검증
    amount = offer_data[:amount].to_i
    if amount <= 0
      redirect_to chat_room_path(@chat_room), alert: "유효하지 않은 금액입니다."
      return
    end
  end

  # 기존 주문 찾기 또는 새로 생성
  def find_or_create_order
    if @post.present?
      find_or_create_post_order
    elsif @offer_message.present?
      find_or_create_offer_order
    end
  end

  def find_or_create_post_order
    # 대기 중인 주문이 있으면 재사용
    existing_order = current_user.orders.pending.find_by(post: @post)

    if existing_order
      payment = existing_order.payments.pending.first || create_new_payment(existing_order)
      return OpenStruct.new(
        success?: true,
        order: existing_order,
        payment: payment,
        errors: []
      )
    end

    # 새 주문 생성
    Orders::CreateService.new(user: current_user, post: @post).call
  end

  def find_or_create_offer_order
    # 해당 거래 제안에 대한 대기 중인 주문이 있으면 재사용
    existing_order = current_user.orders.pending.find_by(offer_message: @offer_message)

    if existing_order
      payment = existing_order.payments.pending.first || create_new_payment(existing_order)
      return OpenStruct.new(
        success?: true,
        order: existing_order,
        payment: payment,
        errors: []
      )
    end

    # 새 주문 생성
    Orders::CreateService.new(
      user: current_user,
      chat_room: @chat_room,
      offer_message: @offer_message
    ).call
  end

  # 새 결제 레코드 생성 (기존 주문에 대해)
  def create_new_payment(order)
    Payment.create!(
      order: order,
      user: current_user,
      amount: order.amount
    )
  end

  # 결제 컨텍스트에 따른 리다이렉트
  def redirect_back_or_root(message)
    if @post.present?
      redirect_to post_path(@post), alert: message
    elsif @chat_room.present?
      redirect_to chat_room_path(@chat_room), alert: message
    else
      redirect_to root_path, alert: message
    end
  end

  # 토스페이먼츠 클라이언트 키
  # Production: credentials 필수
  # Development/Test: 테스트 키 폴백 허용
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

  # 환경별 웹훅 서명 검증
  # Production: 서명 검증 필수 (webhook_secret 미설정 시 거부)
  # Development/Test: webhook_secret 미설정 시 경고 후 허용
  def verify_webhook_with_signature(payload, signature)
    secret = webhook_secret

    if secret.blank?
      if Rails.env.production?
        # Production에서는 webhook_secret 필수
        Rails.logger.error "[PaymentsController#webhook] SECURITY: webhook_secret not configured in production. Rejecting webhook."
        return false
      else
        # Development/Test에서는 경고만 출력하고 허용
        Rails.logger.warn "[PaymentsController#webhook] webhook_secret not configured. Skipping signature verification (development only)."
        return true
      end
    end

    # 서명 검증 수행
    unless verify_webhook_signature(payload, signature)
      Rails.logger.warn "[PaymentsController#webhook] Invalid signature"
      return false
    end

    true
  end

  # 웹훅 서명 검증 (HMAC-SHA256)
  # 토스페이먼츠 공식 문서: https://docs.tosspayments.com/guides/webhook#서명-검증
  def verify_webhook_signature(payload, signature)
    return false if signature.blank?

    expected_signature = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new("sha256"),
      webhook_secret,
      payload
    )

    # 타이밍 공격 방지를 위한 secure_compare 사용
    ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
  end

  # 웹훅 시크릿 키
  def webhook_secret
    Rails.application.credentials.dig(:toss, :webhook_secret)
  end

  # 웹훅: 결제 상태 변경 처리
  def handle_payment_status_change(payload)
    data = payload[:data]
    payment_key = data[:paymentKey]
    status = data[:status]

    payment = Payment.find_by(payment_key: payment_key)
    return unless payment

    case status
    when "DONE"
      payment.update!(status: :done) unless payment.done?
    when "CANCELED"
      payment.mark_as_cancelled!
    end
  end

  # 웹훅: 가상계좌 입금 확인 처리
  def handle_virtual_account_deposit(payload)
    data = payload[:data]
    order_id = data[:orderId]
    status = data[:status]

    payment = Payment.find_by_toss_order_id(order_id)
    return unless payment

    Rails.logger.info "[PaymentsController#webhook] Virtual account deposit: #{order_id}, status: #{status}"

    case status
    when "DONE"
      # 입금 완료
      if payment.confirm_virtual_account_deposit!(data)
        Rails.logger.info "[PaymentsController#webhook] Virtual account deposit confirmed: #{order_id}"
      end
    when "CANCELED"
      # 가상계좌 취소 (입금 기한 초과 등)
      payment.mark_as_cancelled!
      Rails.logger.info "[PaymentsController#webhook] Virtual account cancelled: #{order_id}"
    end
  end
end
