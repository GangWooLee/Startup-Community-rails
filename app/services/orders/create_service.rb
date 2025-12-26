# 주문 생성 서비스
# 외주 글에 대한 주문 및 결제 레코드 생성
module Orders
  class CreateService
    # 결과 객체
    Result = Struct.new(:success?, :order, :payment, :errors, keyword_init: true) do
      def failure?
        !success?
      end
    end

    def initialize(user:, post:)
      @user = user
      @post = post
      @errors = []
    end

    # 주문 생성 실행
    # @return [Result] 생성된 주문 및 결제 정보
    def call
      validate!
      return failure_result if @errors.any?

      ActiveRecord::Base.transaction do
        create_order!
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
      @errors << "게시글을 찾을 수 없습니다." unless @post
      return if @errors.any?

      @errors << "외주 글만 결제할 수 있습니다." unless @post.outsourcing?
      @errors << "가격이 설정되지 않은 글입니다." unless @post.price.present? && @post.price.positive?
      @errors << "본인의 글은 결제할 수 없습니다." if @post.user_id == @user.id
      @errors << "이미 주문한 글입니다." if existing_order?
    end

    # 기존 주문 확인 (취소되지 않은 주문)
    def existing_order?
      @user.orders.where(post: @post).where.not(status: :cancelled).exists?
    end

    # 주문 생성
    def create_order!
      @order = Order.create!(
        user: @user,
        post: @post,
        seller: @post.user,
        title: @post.title,
        amount: @post.price,
        description: order_description,
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

    # 주문 설명 생성
    def order_description
      "#{@post.category_label} - #{@post.service_type_label}"
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
