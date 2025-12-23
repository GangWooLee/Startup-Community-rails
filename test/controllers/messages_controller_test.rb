require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user1 = users(:one)
    @user2 = users(:two)
    @chat_room = ChatRoom.find_or_create_between(@user1, @user2)
  end

  test "should create message in chat room" do
    log_in_as(@user1)

    assert_difference "Message.count", 1 do
      post chat_room_messages_url(@chat_room), params: {
        message: { content: "Hello, World!" }
      }
    end

    message = Message.last
    assert_equal "Hello, World!", message.content
    assert_equal @user1.id, message.sender_id
    assert_equal @chat_room.id, message.chat_room_id
  end

  test "should respond with turbo stream when creating message" do
    log_in_as(@user1)

    post chat_room_messages_url(@chat_room), params: {
      message: { content: "Test message" }
    }, as: :turbo_stream

    assert_response :success
    assert_match /turbo-stream/, response.body
  end

  test "should not create empty message" do
    log_in_as(@user1)

    assert_no_difference "Message.count" do
      post chat_room_messages_url(@chat_room), params: {
        message: { content: "" }
      }
    end
  end

  test "should not allow non-participant to send message" do
    other_user = users(:three)
    log_in_as(other_user)

    assert_no_difference "Message.count" do
      post chat_room_messages_url(@chat_room), params: {
        message: { content: "Unauthorized message" }
      }
    end

    # Controller returns 403 Forbidden for non-participants
    assert_response :forbidden
  end

  test "should require login to send message" do
    assert_no_difference "Message.count" do
      post chat_room_messages_url(@chat_room), params: {
        message: { content: "Unauthenticated message" }
      }
    end

    assert_redirected_to login_url
  end
end
