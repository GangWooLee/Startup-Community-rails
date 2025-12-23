class AddMessageTypeToMessages < ActiveRecord::Migration[8.1]
  def change
    # message_type: text(일반), system(시스템 알림), profile_card(프로필 전송), deal_confirm(거래 확정)
    add_column :messages, :message_type, :string, default: "text"

    # metadata: 시스템 메시지나 카드 전송 시 추가 데이터 저장 (JSON)
    add_column :messages, :metadata, :json
  end
end
