class CreateChatRoomParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_room_participants do |t|
      t.references :chat_room, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :last_read_at

      t.timestamps
    end

    add_index :chat_room_participants, [:chat_room_id, :user_id], unique: true
    add_index :chat_room_participants, [:user_id, :chat_room_id]
  end
end
