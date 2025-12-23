require "test_helper"

class ChatRoomParticipantTest < ActiveSupport::TestCase
  setup do
    @user1 = users(:one)
    @user2 = users(:two)
    @chat_room = ChatRoom.find_or_create_between(@user1, @user2)
    @participant = @chat_room.participants.find_by(user: @user1)
  end

  test "should belong to chat room" do
    assert_respond_to @participant, :chat_room
    assert_equal @chat_room, @participant.chat_room
  end

  test "should belong to user" do
    assert_respond_to @participant, :user
    assert_equal @user1, @participant.user
  end

  test "should calculate unread count" do
    # No messages yet
    assert_equal 0, @participant.unread_count

    # Add messages from other user
    Message.create!(chat_room: @chat_room, sender: @user2, content: "Hello")
    Message.create!(chat_room: @chat_room, sender: @user2, content: "World")

    assert_equal 2, @participant.unread_count
  end

  test "should not count own messages as unread" do
    Message.create!(chat_room: @chat_room, sender: @user1, content: "My message")

    assert_equal 0, @participant.unread_count
  end

  test "should mark as read" do
    Message.create!(chat_room: @chat_room, sender: @user2, content: "Unread")

    assert @participant.unread_count > 0

    @participant.mark_as_read!
    assert_equal 0, @participant.unread_count
  end

  test "should have unique user per chat room" do
    duplicate = ChatRoomParticipant.new(chat_room: @chat_room, user: @user1)
    assert_not duplicate.valid?
  end
end
