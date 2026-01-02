class AddHiddenToChatRoomParticipants < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_room_participants, :hidden, :boolean, default: false, null: false
  end
end
