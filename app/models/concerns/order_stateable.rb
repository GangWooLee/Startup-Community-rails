# frozen_string_literal: true

# 주문 상태 관련 메서드
# Order 모델에서 추출된 concern
module OrderStateable
  extend ActiveSupport::Concern

  included do
    after_update :update_offer_message_status, if: :saved_change_to_status?
    after_update :send_chat_system_message, if: :saved_change_to_status?
  end

  # === 상태 변경 ===

  # 결제 완료 처리
  def mark_as_paid!(payment = nil)
    update!(
      status: :paid,
      paid_at: Time.current
    )
  end

  # 작업 진행 중으로 변경 (UI 구분용)
  def mark_as_in_progress!
    return unless paid?

    update!(status: :in_progress)
  end

  # 거래 확정 처리 (구매자가 확정)
  def confirm!
    return false unless can_confirm?

    transaction do
      update!(
        status: :completed,
        completed_at: Time.current
      )
      # TODO: 실제 정산 처리 (Phase 5)
      # SettlementService.new(self).process!
    end
    true
  end

  # 취소 처리
  def mark_as_cancelled!
    update!(
      status: :cancelled,
      cancelled_at: Time.current
    )
  end

  # 환불 처리
  def mark_as_refunded!
    update!(
      status: :refunded,
      refunded_at: Time.current
    )
  end

  # === 상태 확인 ===

  # 결제 가능 여부
  def can_pay?
    pending?
  end

  # 거래 확정 가능 여부 (결제 완료 또는 작업 진행 중일 때만)
  def can_confirm?
    paid? || in_progress?
  end

  # 취소 가능 여부
  def can_cancel?
    (paid? || in_progress?) && created_at > 7.days.ago  # 7일 이내만 취소 가능
  end

  # 에스크로 보관 중인지 확인
  def escrow_held?
    paid? || in_progress?
  end

  # === 상태 표시 ===

  # 상태 표시 (한글)
  def status_label
    case status
    when "pending" then "결제 대기"
    when "paid" then "결제 완료"
    when "in_progress" then "작업 진행 중"
    when "completed" then "거래 완료"
    when "cancelled" then "취소됨"
    when "refunded" then "환불됨"
    when "disputed" then "분쟁 중"
    else status
    end
  end

  private

  # 상태 변경 시 거래 제안 메시지 상태 업데이트
  def update_offer_message_status
    return unless offer_message.present?

    new_status = case status
    when "paid", "in_progress" then "paid"
    when "completed" then "completed"
    when "cancelled", "refunded" then "cancelled"
    end

    offer_message.update_offer_status!(new_status) if new_status
  end

  # 상태 변경 시 채팅방에 시스템 메시지 전송
  def send_chat_system_message
    return unless chat_room.present?

    message_content = case status
    when "paid"
                        "💸 결제가 완료되었습니다! 플랫폼이 #{formatted_amount}을 안전하게 보관 중입니다."
    when "completed"
                        "✅ 거래가 확정되었습니다! #{seller.name}님에게 #{formatted_settlement_amount}이 정산됩니다."
    when "cancelled"
                        "❌ 주문이 취소되었습니다."
    when "refunded"
                        "💰 환불이 완료되었습니다."
    end

    return unless message_content

    chat_room.messages.create!(
      sender: user,  # 시스템 메시지지만 발신자 필요
      message_type: :system,
      content: message_content
    )
  end
end
