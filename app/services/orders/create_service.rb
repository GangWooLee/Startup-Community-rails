# 주문 생성 서비스
# 외주 글 또는 채팅 거래 제안에 대한 주문 및 결제 레코드 생성
# 지원 방식:
# 1. Post 기반 주문: CreateService.new(user:, post:)
# 2. 채팅 거래 제안 기반 주문: CreateService.new(user:, chat_room:, offer_message:)
module Orders
  class CreateService
    # 결과 객체
    Result = Struct.new(:success?, :order, :payment, :errors, keyword_init: true) do
      def failure?
        !success?
      end
    end

    def initialize(user:, post: nil, chat_room: nil, offer_message: nil)
      @user = user
      @post = post
      @chat_room = chat_room
      @offer_message = offer_message
      @errors = []
    end

    # 주문 생성 실행
    # @return [Result] 생성된 주문 및 결제 정보
    def call
      validate!
      return failure_result if @errors.any?

      ActiveRecord::Base.transaction do
        if @post.present?
          create_post_order!
        elsif @offer_message.present?
          create_offer_order!
        end
        create_payment!
      end

      Rails.logger.info "[Orders::CreateService] Order created: #{@order.order_number}"

      Result.new(
        success?: true,
        order: @order,
        payment: @payment,
        errors: []
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[Orders::CreateService] Validation failed: #{e.message}"
      @errors << e.message
      failure_result
    rescue StandardError => e
      Rails.logger.error "[Orders::CreateService] Error: #{e.class} - #{e.message}"
      @errors << "주문 생성 중 오류가 발생했습니다."
      failure_result
    end

    private

    # 사전 검증
    def validate!
      @errors << "로그인이 필요합니다." unless @user

      if @post.present?
        validate_post_order!
      elsif @offer_message.present?
        validate_offer_order!
      else
        @errors << "주문 대상을 찾을 수 없습니다."
      end
    end

    # Post 기반 주문 검증
    def validate_post_order!
      @errors << "게시글을 찾을 수 없습니다." unless @post
      return if @errors.any?

      @errors << "외주 글만 결제할 수 있습니다." unless @post.outsourcing?
      @errors << "가격이 설정되지 않은 글입니다." unless @post.price.present? && @post.price.positive?
      @errors << "본인의 글은 결제할 수 없습니다." if @post.user_id == @user.id
      @errors << "이미 주문한 글입니다." if existing_post_order?
    end

    # 채팅 거래 제안 기반 주문 검증
    def validate_offer_order!
      @errors << "거래 제안을 찾을 수 없습니다." unless @offer_message&.offer_card?
      @errors << "채팅방을 찾을 수 없습니다." unless @chat_room
      return if @errors.any?

      offer_data = @offer_message.offer_data
      @errors << "거래 제안 정보가 올바르지 않습니다." unless offer_data

      if offer_data
        @errors << "금액이 유효하지 않습니다." unless offer_data[:amount].to_i.positive?
        @errors << "제목이 필요합니다." if offer_data[:title].blank?
      end

      @errors << "본인이 보낸 제안은 결제할 수 없습니다." if @offer_message.sender_id == @user.id
      @errors << "이미 주문한 거래 제안입니다." if existing_offer_order?
      @errors << "이미 결제된 거래입니다." if @offer_message.offer_paid? || @offer_message.offer_completed?
      @errors << "취소된 거래 제안입니다." if @offer_message.offer_cancelled?
    end

    # 기존 Post 주문 확인 (취소되지 않은 주문)
    def existing_post_order?
      @user.orders.where(post: @post).where.not(status: :cancelled).exists?
    end

    # 기존 거래 제안 주문 확인 (취소되지 않은 주문)
    def existing_offer_order?
      @user.orders.where(offer_message: @offer_message).where.not(status: :cancelled).exists?
    end

    # Post 기반 주문 생성
    def create_post_order!
      @order = Order.create!(
        user: @user,
        post: @post,
        seller: @post.user,
        title: @post.title,
        amount: @post.price,
        description: post_order_description,
        order_type: :outsourcing,
        status: :pending
      )
    end

    # 채팅 거래 제안 기반 주문 생성
    def create_offer_order!
      offer_data = @offer_message.offer_data
      seller = @chat_room.other_participant(@user)

      @order = Order.create!(
        user: @user,
        seller: seller,
        chat_room: @chat_room,
        offer_message: @offer_message,
        title: offer_data[:title],
        amount: offer_data[:amount].to_i,
        description: offer_order_description(offer_data),
        order_type: :outsourcing,
        status: :pending
      )
    end

    # 결제 레코드 생성 (결제 위젯에서 사용)
    def create_payment!
      @payment = Payment.create!(
        order: @order,
        user: @user,
        amount: @order.amount
      )
    end

    # Post 기반 주문 설명 생성
    def post_order_description
      "#{@post.category_label} - #{@post.service_type_label}"
    end

    # 채팅 거래 제안 기반 주문 설명 생성
    def offer_order_description(offer_data)
      description = offer_data[:description].presence || "채팅 거래 제안"
      deadline = offer_data[:deadline].present? ? " (기한: #{offer_data[:deadline]})" : ""
      "#{description}#{deadline}"
    end

    # 실패 결과 반환
    def failure_result
      Result.new(
        success?: false,
        order: nil,
        payment: nil,
        errors: @errors
      )
    end
  end
end
