class RemoveHiddenFromChatRoomParticipants < ActiveRecord::Migration[8.1]
  def change
    # hidden 컬럼 제거 - deleted_at으로 통일
    # soft delete는 deleted_at timestamp 방식이 Rails 관용적 패턴
    remove_column :chat_room_participants, :hidden, :boolean, default: false, null: false
  end
end
