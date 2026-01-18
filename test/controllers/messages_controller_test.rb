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

  test "should respond with success when creating message via turbo stream" do
    log_in_as(@user1)

    post chat_room_messages_url(@chat_room), params: {
      message: { content: "Test message" }
    }, as: :turbo_stream

    # 메시지는 브로드캐스트로 추가되므로 빈 응답 반환
    assert_response :success
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

  # ===== 중복 전송 방지 테스트 =====

  test "should handle korean message correctly" do
    log_in_as(@user1)

    korean_content = "안녕하세요 한글 테스트입니다 😀"

    assert_difference "Message.count", 1 do
      post chat_room_messages_url(@chat_room), params: {
        message: { content: korean_content }
      }, as: :turbo_stream
    end

    assert_response :success
    message = Message.last
    assert_equal korean_content, message.content
  end

  test "should create each message when sent with different content" do
    log_in_as(@user1)

    # 서로 다른 내용의 메시지는 각각 생성되어야 함
    assert_difference "Message.count", 2 do
      post chat_room_messages_url(@chat_room), params: {
        message: { content: "첫 번째 메시지" }
      }, as: :turbo_stream

      post chat_room_messages_url(@chat_room), params: {
        message: { content: "두 번째 메시지" }
      }, as: :turbo_stream
    end
  end

  # ===== 동시 요청 처리 테스트 =====

  test "should handle concurrent requests with different content" do
    log_in_as(@user1)
    initial_count = @chat_room.messages.count

    # 서로 다른 내용의 동시 요청은 모두 처리되어야 함
    threads = []
    2.times do |i|
      threads << Thread.new do
        post chat_room_messages_url(@chat_room), params: {
          message: { content: "동시 테스트_#{i}_#{SecureRandom.hex(4)}" }
        }, as: :turbo_stream
      end
    end

    threads.each(&:join)

    # 2개의 서로 다른 메시지가 생성됨
    assert_equal initial_count + 2, @chat_room.messages.reload.count
  end

  # ===== 파일 업로드 테스트 =====

  test "should create message with image attachment" do
    log_in_as(@user1)

    assert_difference "Message.count", 1 do
      post chat_room_messages_url(@chat_room), params: {
        message: {
          content: "이미지 첨부 테스트",
          image: fixture_file_upload("test_image.png", "image/png")
        }
      }
    end

    message = Message.last
    assert message.image.attached?
    assert_equal "이미지 첨부 테스트", message.content
  end

  test "should create message with only image (no content)" do
    log_in_as(@user1)

    assert_difference "Message.count", 1 do
      post chat_room_messages_url(@chat_room), params: {
        message: {
          content: "",
          image: fixture_file_upload("test_image.png", "image/png")
        }
      }
    end

    message = Message.last
    assert message.image.attached?
  end

  test "should require content or image" do
    log_in_as(@user1)

    # 빈 메시지는 생성되지 않아야 함
    assert_no_difference "Message.count" do
      post chat_room_messages_url(@chat_room), params: {
        message: {
          content: ""
          # 이미지도 없음
        }
      }
    end
  end
end
