# frozen_string_literal: true

module Payments
  # 결제 자격 검증 서비스
  # 사용: Payments::EligibilityValidator.new(user:, post: @post).call
  #      Payments::EligibilityValidator.new(user:, offer_message: @msg, chat_room: @room).call
  #
  # 반환: Result 객체 (success?, errors, redirect_path)
  class EligibilityValidator
    Result = Struct.new(:success?, :errors, :redirect_path, :alert_message, keyword_init: true) do
      def failure?
        !success?
      end
    end

    attr_reader :user, :post, :offer_message, :chat_room

    def initialize(user:, post: nil, offer_message: nil, chat_room: nil)
      @user = user
      @post = post
      @offer_message = offer_message
      @chat_room = chat_room
      @errors = []
    end

    def call
      if post.present?
        validate_post_payment
      elsif offer_message.present?
        validate_offer_payment
      else
        add_error("결제 대상을 찾을 수 없습니다.", redirect_to: :root)
      end

      build_result
    end

    private

    def validate_post_payment
      unless post.outsourcing?
        return add_error("외주 글만 결제할 수 있습니다.", redirect_to: :post)
      end

      unless post.payable?
        return add_error("가격이 설정되지 않은 글입니다.", redirect_to: :post)
      end

      if post.owned_by?(user)
        return add_error("본인의 글은 결제할 수 없습니다.", redirect_to: :post)
      end

      if post.paid_by?(user)
        add_error("이미 결제한 글입니다.", redirect_to: :post)
      end
    end

    def validate_offer_payment
      offer_data = offer_message.offer_data

      unless offer_data.present?
        return add_error("거래 제안 정보가 올바르지 않습니다.", redirect_to: :chat_room)
      end

      if offer_message.offer_paid? || offer_message.offer_completed?
        return add_error("이미 결제된 거래입니다.", redirect_to: :chat_room)
      end

      if offer_message.offer_cancelled?
        return add_error("취소된 거래 제안입니다.", redirect_to: :chat_room)
      end

      amount = offer_data[:amount].to_i
      if amount <= 0
        add_error("유효하지 않은 금액입니다.", redirect_to: :chat_room)
      end
    end

    def add_error(message, redirect_to:)
      @errors << message
      @redirect_target = redirect_to
    end

    def build_result
      if @errors.empty?
        Result.new(success?: true, errors: [], redirect_path: nil, alert_message: nil)
      else
        Result.new(
          success?: false,
          errors: @errors,
          redirect_path: resolve_redirect_path(@redirect_target),
          alert_message: @errors.first
        )
      end
    end

    def resolve_redirect_path(target)
      case target
      when :post
        [ :post_path, post ]
      when :chat_room
        [ :chat_room_path, chat_room ]
      when :root
        [ :root_path ]
      end
    end
  end
end
