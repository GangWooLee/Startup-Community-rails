require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @user1 = users(:one)
    @user2 = users(:two)
    @chat_room = ChatRoom.find_or_create_between(@user1, @user2)
  end

  test "should create valid message" do
    message = Message.new(chat_room: @chat_room, sender: @user1, content: "Hello!")
    assert message.valid?
  end

  test "should require content" do
    message = Message.new(chat_room: @chat_room, sender: @user1, content: "")
    assert_not message.valid?
    assert message.errors[:content].any?
  end

  test "should require chat room" do
    message = Message.new(sender: @user1, content: "Hello")
    assert_not message.valid?
  end

  test "should require sender" do
    message = Message.new(chat_room: @chat_room, content: "Hello")
    assert_not message.valid?
  end

  test "should increment chat room messages count" do
    assert_difference -> { @chat_room.reload.messages_count }, 1 do
      Message.create!(chat_room: @chat_room, sender: @user1, content: "Test")
    end
  end

  test "should update chat room last_message_at" do
    old_time = @chat_room.last_message_at

    Message.create!(chat_room: @chat_room, sender: @user1, content: "Test")
    @chat_room.reload

    assert_not_equal old_time, @chat_room.last_message_at
  end

  test "should limit content length" do
    long_content = "a" * 2001
    message = Message.new(chat_room: @chat_room, sender: @user1, content: long_content)
    assert_not message.valid?
  end
end
