# frozen_string_literal: true

module Messages
  # 메시지 수신자에게 알림 생성
  #
  # 시스템 메시지(system, deal_confirm)에는 알림을 생성하지 않음
  class NotificationHandler
    def self.call(message)
      new(message).call
    end

    def initialize(message)
      @message = message
      @chat_room = message.chat_room
      @sender = message.sender
      @sender_id = message.sender_id
    end

    def call
      # 시스템 메시지에는 알림 생성하지 않음
      return if @message.system_message?

      create_notifications
    end

    private

    def create_notifications
      @chat_room.participants.where.not(user_id: @sender_id).each do |participant|
        Notification.create(
          recipient: participant.user,
          actor: @sender,
          action: "message",
          notifiable: @message
        )
      end
    end
  end
end
