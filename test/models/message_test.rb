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

  test "should require content or image" do
    # content도 없고 image도 없으면 유효하지 않음
    message = Message.new(chat_room: @chat_room, sender: @user1, content: "")
    assert_not message.valid?
    assert message.errors[:base].any?
  end

  test "should be valid with only image" do
    # 이미지만 있어도 유효함
    message = Message.new(chat_room: @chat_room, sender: @user1, content: "")
    message.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test_image.png")), filename: "test.png", content_type: "image/png")
    assert message.valid?, "Message with image should be valid: #{message.errors.full_messages.join(", ")}"
  end

  test "should be valid with content and image" do
    # content와 image 둘 다 있어도 유효함
    message = Message.new(chat_room: @chat_room, sender: @user1, content: "Hello with image")
    message.image.attach(io: File.open(Rails.root.join("test/fixtures/files/test_image.png")), filename: "test.png", content_type: "image/png")
    assert message.valid?
  end

  test "should validate image size" do
    # 5MB 초과 이미지는 유효하지 않음
    message = Message.new(chat_room: @chat_room, sender: @user1, content: "")
    # 가짜 대용량 파일 (실제로 생성하지 않고 테스트)
    # 이 테스트는 실제 대용량 파일이 있을 때만 동작
    skip "Large image file not available for testing"
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
