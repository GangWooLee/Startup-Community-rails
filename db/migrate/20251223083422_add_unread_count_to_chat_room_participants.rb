class AddUnreadCountToChatRoomParticipants < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_room_participants, :unread_count, :integer, default: 0, null: false
  end
end
