class AddContextToChatRooms < ActiveRecord::Migration[8.1]
  def change
    # source_post: 어떤 게시글을 통해 채팅이 시작되었는지 (nullable - DM으로 시작할 수도 있음)
    add_reference :chat_rooms, :source_post, null: true, foreign_key: { to_table: :posts }

    # initiator: 채팅을 먼저 시작한 사람 (지원자/문의자)
    add_reference :chat_rooms, :initiator, null: true, foreign_key: { to_table: :users }

    # deal_status: 거래 상태 (pending, confirmed, cancelled)
    add_column :chat_rooms, :deal_status, :string, default: "pending"
  end
end
