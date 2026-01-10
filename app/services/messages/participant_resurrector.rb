# frozen_string_literal: true

module Messages
  # 채팅방을 나간(숨긴) 참여자 복구
  #
  # 새 메시지가 도착하면 숨겨진 참여자들을 다시 활성화하고
  # 실제 안읽은 메시지 수를 재계산합니다.
  class ParticipantResurrector
    def self.call(message)
      new(message).call
    end

    def initialize(message)
      @message = message
      @chat_room = message.chat_room
    end

    def call
      hidden_participants = @chat_room.participants.where.not(deleted_at: nil)
      return if hidden_participants.empty?

      resurrect_participants(hidden_participants)
      broadcast_badge_updates(hidden_participants.reload)
    end

    private

    # 각 참여자별로 실제 안읽은 메시지 수 계산 후 복구
    def resurrect_participants(hidden_participants)
      hidden_participants.each do |participant|
        actual_unread = calculate_unread_count(participant)
        participant.update!(deleted_at: nil, unread_count: actual_unread)
      end
    end

    # deleted 상태에서 받은 메시지 포함하여 실제 unread_count 계산
    def calculate_unread_count(participant)
      @chat_room.messages
                .where.not(sender_id: participant.user_id)
                .where("created_at > COALESCE(?, '1970-01-01')", participant.last_read_at)
                .count
    end

    # 복구된 참여자들에게 채팅 뱃지 업데이트
    def broadcast_badge_updates(participants)
      participants.each do |participant|
        Turbo::StreamsChannel.broadcast_replace_to(
          "user_#{participant.user_id}_chat_badge",
          target: "chat_unread_badge",
          partial: "shared/chat_unread_badge",
          locals: { count: participant.user.reload.total_unread_messages }
        )
      end
    end
  end
end
