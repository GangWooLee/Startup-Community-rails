# frozen_string_literal: true

require "test_helper"

module Messages
  class NotificationHandlerTest < ActiveSupport::TestCase
    setup do
      @user1 = users(:one)
      @user2 = users(:two)
      @chat_room = ChatRoom.find_or_create_between(@user1, @user2)
    end

    test "creates notification for recipient" do
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "알림 테스트"
      )

      assert_difference -> { Notification.count }, 1 do
        Messages::NotificationHandler.call(message)
      end

      notification = Notification.last
      assert_equal @user2, notification.recipient
      assert_equal @user1, notification.actor
      assert_equal "message", notification.action
      assert_equal message, notification.notifiable
    end

    test "does not create notification for system message" do
      system_message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "시스템 메시지",
        message_type: :system
      )

      assert_no_difference -> { Notification.count } do
        Messages::NotificationHandler.call(system_message)
      end
    end

    test "does not create notification for deal_confirm message" do
      deal_message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "거래 확정",
        message_type: :deal_confirm
      )

      assert_no_difference -> { Notification.count } do
        Messages::NotificationHandler.call(deal_message)
      end
    end

    test "does not create notification for sender" do
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "테스트"
      )

      Messages::NotificationHandler.call(message)

      # sender에게는 알림이 생성되지 않음
      sender_notifications = Notification.where(recipient: @user1, notifiable: message)
      assert_equal 0, sender_notifications.count
    end

    test "creates notifications for all recipients in group chat" do
      @user3 = users(:three)

      # 그룹 채팅방 시뮬레이션 (participants 수동 추가)
      @chat_room.participants.find_or_create_by!(user: @user3)

      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "그룹 메시지"
      )

      # user2, user3에게 알림 생성
      assert_difference -> { Notification.count }, 2 do
        Messages::NotificationHandler.call(message)
      end
    end
  end
end
