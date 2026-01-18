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

    # StringIO를 사용하여 가상의 대용량 파일 생성 (6MB)
    large_file_content = "x" * (6 * 1024 * 1024)
    large_file = StringIO.new(large_file_content)
    large_file.define_singleton_method(:original_filename) { "large_image.png" }
    large_file.define_singleton_method(:content_type) { "image/png" }

    message.image.attach(io: large_file, filename: "large_image.png", content_type: "image/png")

    assert_not message.valid?
    assert message.errors[:image].any? { |e| e.include?("5MB") || e.include?("too large") || e.include?("크") }
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

  # ===== 한글/특수문자 처리 테스트 =====

  test "should handle korean characters correctly" do
    korean_texts = [
      "안녕하세요",
      "한글 테스트입니다",
      "자음모음 ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ",
      "긴 한글 " + "가" * 500  # 500자 한글
    ]

    korean_texts.each do |text|
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: text
      )
      assert_equal text, message.reload.content, "한글 '#{text[0..20]}...'가 올바르게 저장되어야 함"
    end
  end

  test "should handle emoji correctly" do
    emoji_texts = [
      "이모지 테스트 😀",
      "🎉🚀💻",
      "한글과 이모지 혼합 안녕 👋",
      "복합 이모지 👨‍👩‍👧‍👦"  # 가족 이모지 (ZWJ sequence)
    ]

    emoji_texts.each do |text|
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: text
      )
      assert_equal text, message.reload.content, "이모지 '#{text}'가 올바르게 저장되어야 함"
    end
  end

  test "should handle special characters correctly" do
    special_texts = [
      "특수문자 포함 !@#$%^&*()",
      "HTML 태그 <script>alert('xss')</script>",
      "SQL 인젝션 시도 '; DROP TABLE messages; --",
      "줄바꿈\n포함\r\n텍스트"
    ]

    special_texts.each do |text|
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: text
      )
      assert_equal text, message.reload.content, "특수문자 '#{text[0..20]}...'가 올바르게 저장되어야 함"
    end
  end

  # ===== 5초 내 중복 메시지 방지 테스트 =====

  test "should prevent duplicate message within 5 seconds" do
    same_content = "중복 방지 테스트"

    # 첫 번째 메시지 생성
    Message.create!(chat_room: @chat_room, sender: @user1, content: same_content)

    # 5초 내 동일 내용 전송 시도 → 유효성 검사 실패
    duplicate = Message.new(chat_room: @chat_room, sender: @user1, content: same_content)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:content], "최근 5초 내 동일한 메시지가 전송되었습니다"
  end

  test "should allow same content from different sender" do
    same_content = "같은 내용"

    # user1이 먼저 전송
    Message.create!(chat_room: @chat_room, sender: @user1, content: same_content)

    # user2는 같은 내용이어도 전송 가능
    message2 = Message.new(chat_room: @chat_room, sender: @user2, content: same_content)
    assert message2.valid?, "다른 발신자는 같은 내용을 보낼 수 있어야 함"
  end

  test "should allow same content in different chat room" do
    same_content = "같은 내용"

    # 첫 번째 채팅방에 전송
    Message.create!(chat_room: @chat_room, sender: @user1, content: same_content)

    # 다른 채팅방 생성
    @user3 = users(:three)
    other_chat_room = ChatRoom.find_or_create_between(@user1, @user3)

    # 다른 채팅방에서는 같은 내용 전송 가능
    message2 = Message.new(chat_room: other_chat_room, sender: @user1, content: same_content)
    assert message2.valid?, "다른 채팅방에서는 같은 내용을 보낼 수 있어야 함"
  end

  test "should only apply duplicate check to text messages" do
    same_content = "시스템 메시지 중복 테스트"

    # 시스템 메시지는 중복 체크 대상 아님
    Message.create!(
      chat_room: @chat_room,
      sender: @user1,
      content: same_content,
      message_type: :system
    )

    # 같은 내용의 시스템 메시지도 생성 가능
    system_message2 = Message.new(
      chat_room: @chat_room,
      sender: @user1,
      content: same_content,
      message_type: :system
    )
    assert system_message2.valid?, "시스템 메시지는 중복 체크 대상이 아니어야 함"
  end

  test "should allow sending after 5 seconds wait" do
    same_content = "5초 후 전송 테스트"

    # 첫 번째 메시지 생성 (5초 전 시간으로 설정)
    Message.create!(
      chat_room: @chat_room,
      sender: @user1,
      content: same_content,
      created_at: 6.seconds.ago
    )

    # 5초 후에는 같은 내용 전송 가능
    message2 = Message.new(chat_room: @chat_room, sender: @user1, content: same_content)
    assert message2.valid?, "5초 후에는 같은 내용을 보낼 수 있어야 함"
  end

  # ===== 동시성 테스트 =====

  test "should handle concurrent message creation correctly" do
    initial_count = @chat_room.messages.count
    threads = []
    messages_created = Concurrent::Array.new

    2.times do |i|
      threads << Thread.new do
        msg = Message.create!(
          chat_room: @chat_room,
          sender: i == 0 ? @user1 : @user2,
          content: "동시 메시지 #{i}_#{SecureRandom.hex(4)}"
        )
        messages_created << msg
      end
    end

    threads.each(&:join)

    assert_equal initial_count + 2, @chat_room.reload.messages.count
    assert_equal 2, messages_created.size
  end
end
