class AddDeletedAtToChatRoomParticipants < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_room_participants, :deleted_at, :datetime
    add_index :chat_room_participants, :deleted_at
  end
end
