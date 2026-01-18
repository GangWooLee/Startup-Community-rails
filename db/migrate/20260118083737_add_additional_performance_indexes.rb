# frozen_string_literal: true

# 추가 성능 인덱스 (2026-01-18)
#
# LCP 최적화 계획 Phase 3.3의 일환으로 추가
#
# 인덱스 설명:
# 1. messages: 채팅방별 최신 메시지 조회 최적화
# 2. posts: 인기 게시글 정렬 최적화
# 3. chat_room_participants: 복합 조건 조회 최적화
class AddAdditionalPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    # messages: 채팅방별 최신 메시지 조회 최적화
    # 사용처: last_message_preview, 메시지 목록 조회
    add_index :messages, [:chat_room_id, :created_at, :sender_id],
              name: "index_messages_on_room_created_sender"

    # posts: 인기 게시글 정렬 (popular scope)
    # 사용처: Post.popular, 커뮤니티 인기 게시글
    add_index :posts, [:likes_count, :views_count],
              name: "index_posts_on_popularity"

    # chat_room_participants: 채팅방-사용자-삭제 복합 조회
    # 사용처: 채팅방 참여자 조회, 읽지 않은 메시지 계산
    add_index :chat_room_participants, [:chat_room_id, :user_id, :deleted_at],
              name: "index_participants_on_room_user_deleted"
  end
end
