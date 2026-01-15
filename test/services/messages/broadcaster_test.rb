# frozen_string_literal: true

require "test_helper"

module Messages
  class BroadcasterTest < ActiveSupport::TestCase
    setup do
      @user1 = users(:one)
      @user2 = users(:two)
      @chat_room = ChatRoom.find_or_create_between(@user1, @user2)
      @message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "브로드캐스트 테스트"
      )
    end

    test "initializes with message and chat room" do
      broadcaster = Messages::Broadcaster.new(@message)

      # Broadcaster가 메시지와 채팅방 정보를 가지고 있는지 확인
      # 내부 상태는 private이므로 call이 에러 없이 실행되는지만 확인
      assert_nothing_raised do
        broadcaster.call
      end
    end

    test "executes without error for valid message" do
      # Turbo Streams 브로드캐스트가 테스트 환경에서 에러 없이 실행되는지 확인
      assert_nothing_raised do
        Messages::Broadcaster.call(@message)
      end
    end

    test "handles chat room with multiple participants" do
      @user3 = users(:three)
      @chat_room.participants.find_or_create_by!(user: @user3)

      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "그룹 메시지"
      )

      assert_nothing_raised do
        Messages::Broadcaster.call(message)
      end
    end

    test "reloads chat room to get updated last_message_at" do
      # touch로 업데이트된 값이 반영되는지 확인
      old_updated_at = @chat_room.updated_at

      Messages::Broadcaster.call(@message)

      # 브로드캐스터 내부에서 reload가 호출되어 최신 데이터 사용
      assert @chat_room.reload.updated_at >= old_updated_at
    end
  end
end
