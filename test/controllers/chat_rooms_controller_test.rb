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

  # ===== profile_overlay 테스트 =====

  test "should return profile overlay for participant" do
    chat_room = ChatRoom.find_or_create_between(@user1, @user2)

    log_in_as(@user1)
    get profile_overlay_chat_room_url(chat_room), as: :turbo_stream

    assert_response :success
  end

  test "should return forbidden for non-participant in profile_overlay" do
    other_user = users(:three)
    chat_room = ChatRoom.find_or_create_between(@user1, @user2)

    log_in_as(other_user)
    get profile_overlay_chat_room_url(chat_room), as: :turbo_stream

    assert_response :forbidden
  end

  # ===== leave (채팅방 나가기) 테스트 =====

  test "should leave chat room (soft delete)" do
    chat_room = ChatRoom.find_or_create_between(@user1, @user2)
    participant = chat_room.participants.find_by(user: @user1)
    assert_nil participant.deleted_at

    log_in_as(@user1)
    delete leave_chat_room_url(chat_room)

    participant.reload
    assert_not_nil participant.deleted_at
    assert_redirected_to chat_rooms_url
  end

  test "should leave chat room via turbo stream" do
    chat_room = ChatRoom.find_or_create_between(@user1, @user2)

    log_in_as(@user1)
    delete leave_chat_room_url(chat_room), as: :turbo_stream

    assert_response :success
  end

  test "should not allow non-participant to leave chat room" do
    other_user = users(:three)
    chat_room = ChatRoom.find_or_create_between(@user1, @user2)

    log_in_as(other_user)
    delete leave_chat_room_url(chat_room)

    assert_redirected_to chat_rooms_url
    assert_equal "채팅방을 찾을 수 없습니다.", flash[:alert]
  end

  # ===== mark_as_read 테스트 =====

  test "should mark as read for participant" do
    chat_room = ChatRoom.find_or_create_between(@user1, @user2)
    Message.create!(chat_room: chat_room, sender: @user2, content: "Test")

    participant = chat_room.participants.find_by(user: @user1)
    assert participant.unread_count > 0

    log_in_as(@user1)
    post mark_as_read_chat_room_url(chat_room)

    assert_response :ok
    participant.reload
    assert_equal 0, participant.unread_count
  end

  test "should return forbidden for non-participant in mark_as_read" do
    other_user = users(:three)
    chat_room = ChatRoom.find_or_create_between(@user1, @user2)

    log_in_as(other_user)
    post mark_as_read_chat_room_url(chat_room)

    assert_response :forbidden
  end

  # ===== search_users 테스트 =====

  test "should search users" do
    log_in_as(@user1)
    get search_users_chat_rooms_url, params: { query: @user2.name }

    assert_response :success
    json = JSON.parse(response.body)
    assert json.any? { |u| u["id"] == @user2.id }
  end

  test "should return empty array for short query" do
    log_in_as(@user1)
    get search_users_chat_rooms_url, params: { query: "" }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal [], json
  end

  test "should not include current user in search results" do
    log_in_as(@user1)
    get search_users_chat_rooms_url, params: { query: @user1.name }

    assert_response :success
    json = JSON.parse(response.body)
    assert json.none? { |u| u["id"] == @user1.id }
  end
end
