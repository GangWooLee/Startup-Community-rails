# frozen_string_literal: true

module Messages
  # Turbo Streams를 통한 실시간 메시지 브로드캐스트
  #
  # 브로드캐스트 대상:
  # 1. 채팅방 메시지 영역 (새 메시지 추가)
  # 2. 채팅 목록 아이템 (최신 메시지 미리보기 업데이트)
  # 3. 채팅 뱃지 (수신자만, 미읽음 수 업데이트)
  class Broadcaster
    def self.call(message)
      new(message).call
    end

    def initialize(message)
      @message = message
      @chat_room = message.chat_room.reload  # touch로 업데이트된 last_message_at 반영
      @sender_id = message.sender_id
    end

    def call
      @chat_room.participants.each do |participant|
        broadcast_to_participant(participant)
      end
    end

    private

    def broadcast_to_participant(participant)
      is_sender = participant.user_id == @sender_id

      broadcast_new_message(participant, is_sender)
      broadcast_chat_list_update(participant, is_sender)
      broadcast_badge_update(participant) unless is_sender
    end

    # 채팅방에 새 메시지 추가
    def broadcast_new_message(participant, is_sender)
      Turbo::StreamsChannel.broadcast_append_to(
        "chat_room_#{@chat_room.id}_user_#{participant.user_id}",
        target: "messages",
        partial: "messages/message",
        locals: {
          message: @message,
          current_user: participant.user,
          is_read: is_sender ? false : true,  # 보낸 사람: 상대방이 안 읽음
          show_profile: true,
          show_time: true
        }
      )
    end

    # 채팅 목록 아이템 업데이트
    def broadcast_chat_list_update(participant, is_sender)
      Turbo::StreamsChannel.broadcast_replace_to(
        "user_#{participant.user_id}_chat_list",
        target: "chat_room_#{@chat_room.id}",
        partial: "chat_rooms/chat_list_item",
        locals: {
          room: @chat_room,
          current_user: participant.user,
          is_active: is_sender
        }
      )
    end

    # 채팅 뱃지 업데이트 (수신자만)
    def broadcast_badge_update(participant)
      Turbo::StreamsChannel.broadcast_replace_to(
        "user_#{participant.user_id}_chat_badge",
        target: "chat_unread_badge",
        partial: "shared/chat_unread_badge",
        locals: { count: participant.user.total_unread_messages }
      )
    end
  end
end
