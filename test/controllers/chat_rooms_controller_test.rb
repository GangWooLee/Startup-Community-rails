require "test_helper"

class ChatRoomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user1 = users(:one)
    @user2 = users(:two)
  end

  test "should redirect to login when not logged in" do
    get chat_rooms_url
    assert_redirected_to login_url
  end

  test "should get index when logged in" do
    log_in_as(@user1)
    get chat_rooms_url
    assert_response :success
  end

  test "should show chat room list with existing rooms" do
    # Create a chat room between user1 and user2
    chat_room = ChatRoom.find_or_create_between(@user1, @user2)
    Message.create!(chat_room: chat_room, sender: @user2, content: "Hello!")

    log_in_as(@user1)
    get chat_rooms_url
    assert_response :success
    assert_select "a[href=?]", chat_room_path(chat_room)
  end

  test "should show empty state when no chat rooms" do
    # Delete all chat rooms for user1
    @user1.chat_rooms.destroy_all

    log_in_as(@user1)
    get chat_rooms_url
    assert_response :success
    assert_match /아직 대화가 없습니다/, response.body
  end

  test "should show chat room detail" do
    chat_room = ChatRoom.find_or_create_between(@user1, @user2)
    Message.create!(chat_room: chat_room, sender: @user2, content: "Test message")

    log_in_as(@user1)
    get chat_room_url(chat_room)
    assert_response :success
    assert_match /Test message/, response.body
  end

  test "should create new chat room with initial message" do
    log_in_as(@user1)
    assert_difference "ChatRoom.count", 1 do
      post chat_rooms_url, params: { user_id: @user2.id, initial_message: "Hello!" }
    end
    assert_redirected_to ChatRoom.last
    assert_equal "Hello!", ChatRoom.last.messages.last.content
  end

  test "should redirect to new_chat_room_path when no existing room and no initial_message" do
    log_in_as(@user1)
    assert_no_difference "ChatRoom.count" do
      post chat_rooms_url, params: { user_id: @user2.id }
    end
    assert_redirected_to new_chat_room_path(recipient_id: @user2.id)
  end

  test "should find existing chat room and redirect to it" do
    # First create a room
    existing_room = ChatRoom.find_or_create_between(@user1, @user2)

    log_in_as(@user1)
    assert_no_difference "ChatRoom.count" do
      post chat_rooms_url, params: { user_id: @user2.id }
    end
    assert_redirected_to existing_room
  end

  test "should not allow viewing other users chat room" do
    other_user = users(:three)
    chat_room = ChatRoom.find_or_create_between(@user2, other_user)

    log_in_as(@user1)
    get chat_room_url(chat_room)
    assert_redirected_to chat_rooms_url
    assert_equal "접근 권한이 없습니다.", flash[:alert]
  end

  test "should mark messages as read when viewing chat room" do
    chat_room = ChatRoom.find_or_create_between(@user1, @user2)
    Message.create!(chat_room: chat_room, sender: @user2, content: "Unread message")

    participant = chat_room.participants.find_by(user: @user1)
    assert participant.unread_count > 0

    log_in_as(@user1)
    get chat_room_url(chat_room)

    participant.reload
    assert_equal 0, participant.unread_count
  end
end
