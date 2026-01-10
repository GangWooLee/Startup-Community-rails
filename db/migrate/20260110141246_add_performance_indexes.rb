# frozen_string_literal: true

# 성능 최적화를 위한 복합 인덱스 추가
#
# 추가 인덱스:
# 1. notifications [:actor_id, :created_at] - actor의 최근 알림 조회
# 2. chat_room_participants [:user_id, :deleted_at] - 사용자의 활성 채팅방 조회
# 3. messages [:created_at DESC] - 최신 메시지 정렬 최적화
class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    # notifications: actor의 최근 알림 조회 최적화
    # 사용처: 알림 목록에서 actor 정보와 함께 최신순 조회
    add_index :notifications, [ :actor_id, :created_at ],
              name: "index_notifications_on_actor_and_created"

    # chat_room_participants: 사용자의 활성 채팅방 목록 최적화
    # 사용처: ChatRoomsController#index에서 deleted_at IS NULL + user_id 조건
    add_index :chat_room_participants, [ :user_id, :deleted_at ],
              name: "index_participants_on_user_and_deleted"

    # messages: 최신 메시지 정렬 최적화
    # 사용처: chat_room.messages.order(created_at: :desc).first
    add_index :messages, :created_at, order: { created_at: :desc },
              name: "index_messages_on_created_at_desc"
  end
end
