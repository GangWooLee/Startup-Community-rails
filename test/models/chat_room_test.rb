require "test_helper"

class ChatRoomTest < ActiveSupport::TestCase
  setup do
    @user1 = users(:one)
    @user2 = users(:two)
  end

  test "should create chat room between two users" do
    chat_room = ChatRoom.find_or_create_between(@user1, @user2)
    assert chat_room.persisted?
    assert_equal 2, chat_room.users.count
    assert_includes chat_room.users, @user1
    assert_includes chat_room.users, @user2
  end

  test "should not create duplicate chat room" do
    room1 = ChatRoom.find_or_create_between(@user1, @user2)
    room2 = ChatRoom.find_or_create_between(@user1, @user2)
    assert_equal room1.id, room2.id
  end

  test "should return nil when creating room with same user" do
    room = ChatRoom.find_or_create_between(@user1, @user1)
    assert_nil room
  end

  test "should return other participant" do
    chat_room = ChatRoom.find_or_create_between(@user1, @user2)
    assert_equal @user2, chat_room.other_participant(@user1)
    assert_equal @user1, chat_room.other_participant(@user2)
  end

  test "should return last message" do
    chat_room = ChatRoom.find_or_create_between(@user1, @user2)
    msg1 = Message.create!(chat_room: chat_room, sender: @user1, content: "First")
    msg2 = Message.create!(chat_room: chat_room, sender: @user2, content: "Second")

    assert_equal msg2, chat_room.last_message
  end

  test "should return unread count for user" do
    chat_room = ChatRoom.find_or_create_between(@user1, @user2)
    Message.create!(chat_room: chat_room, sender: @user2, content: "Message 1")
    Message.create!(chat_room: chat_room, sender: @user2, content: "Message 2")

    assert_equal 2, chat_room.unread_count_for(@user1)
    assert_equal 0, chat_room.unread_count_for(@user2)  # 자신이 보낸 메시지는 안읽음 처리 안함
  end
end
