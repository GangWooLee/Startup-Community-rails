# frozen_string_literal: true

require "test_helper"

module Messages
  class PostCreationServiceTest < ActiveSupport::TestCase
    setup do
      @user1 = users(:one)
      @user2 = users(:two)
      @chat_room = ChatRoom.find_or_create_between(@user1, @user2)
      @message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "테스트 메시지"
      )
    end

    test "marks sender as read" do
      participant = @chat_room.participants.find_by(user_id: @user1.id)
      participant.update!(last_read_at: 1.hour.ago, unread_count: 5)

      Messages::PostCreationService.call(@message)

      participant.reload
      assert_equal 0, participant.unread_count
      assert participant.last_read_at > 1.minute.ago
    end

    test "increments recipient unread count" do
      recipient_participant = @chat_room.participants.find_by(user_id: @user2.id)
      initial_count = recipient_participant.unread_count

      new_message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "새 메시지"
      )

      Messages::PostCreationService.call(new_message)

      recipient_participant.reload
      assert recipient_participant.unread_count > initial_count, "Unread count should have increased"
    end

    test "does not increment sender unread count" do
      sender_participant = @chat_room.participants.find_by(user_id: @user1.id)
      sender_participant.update!(unread_count: 0)

      Messages::PostCreationService.call(@message)

      sender_participant.reload
      assert_equal 0, sender_participant.unread_count
    end

    test "creates notification for recipient" do
      new_message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "알림 테스트 메시지"
      )

      # PostCreationService 호출 시 알림이 생성되는지 확인
      assert_difference -> { Notification.where(recipient: @user2, action: "message").count }, 1 do
        Messages::PostCreationService.call(new_message)
      end
    end

    test "does not create notification for system message" do
      system_message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "시스템 메시지",
        message_type: :system
      )

      assert_no_difference -> { Notification.count } do
        Messages::PostCreationService.call(system_message)
      end
    end

    test "resurrects hidden participants" do
      # user2가 채팅방을 나간 상태
      participant = @chat_room.participants.find_by(user_id: @user2.id)
      participant.update!(deleted_at: 1.day.ago)

      new_message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "복구 테스트"
      )

      Messages::PostCreationService.call(new_message)

      participant.reload
      assert_nil participant.deleted_at, "Hidden participant should be resurrected"
    end
  end
end
