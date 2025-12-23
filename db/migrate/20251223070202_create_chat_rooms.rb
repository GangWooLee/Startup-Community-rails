class CreateChatRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_rooms do |t|
      t.integer :messages_count, default: 0, null: false
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :chat_rooms, :last_message_at
  end
end
