# frozen_string_literal: true

module ChatRooms
  # 채팅방 생성 및 초기 메시지 전송 서비스
  # 새 메시지 패널에서 사용자 선택 후 메시지를 보내는 경우 사용
  class CreateWithMessageService
    attr_reader :chat_room, :message

    def initialize(current_user:, other_user:, content:)
      @current_user = current_user
      @other_user = other_user
      @content = content
    end

    def self.call(...)
      new(...).call
    end

    def call
      @chat_room = ChatRoom.find_or_create_between(
        @current_user,
        @other_user,
        initiator: @current_user
      )

      @message = @chat_room.messages.create!(
        sender: @current_user,
        content: @content
      )

      @chat_room.touch(:last_message_at)

      self
    end

    def messages
      @chat_room.messages.includes(:sender).order(:created_at)
    end

    def other_participant
      @chat_room.other_participant(@current_user)
    end
  end
end
