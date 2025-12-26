# 채팅 기반 거래 제안 시스템을 위한 Orders 테이블 확장
# - Post 없이 ChatRoom/Message 기반 주문 지원
# - 거래 확정 시간 기록
class AddChatRoomToOrders < ActiveRecord::Migration[8.1]
  def change
    # ChatRoom 참조 추가 (채팅 기반 주문용)
    add_reference :orders, :chat_room, foreign_key: true, null: true

    # 거래 제안 메시지 참조 추가 (offer_card 메시지)
    add_reference :orders, :offer_message, foreign_key: { to_table: :messages }, null: true

    # 거래 확정 시간 추가
    add_column :orders, :completed_at, :datetime

    # Post를 선택적으로 변경 (채팅 기반 주문은 post 없이 가능)
    change_column_null :orders, :post_id, true
  end
end
