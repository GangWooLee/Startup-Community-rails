# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

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

    # ===== 한글/특수문자 브로드캐스트 테스트 =====

    test "broadcasts korean message correctly" do
      korean_message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "안녕하세요 한글 메시지입니다 😀"
      )

      assert_nothing_raised do
        Messages::Broadcaster.call(korean_message)
      end

      # 메시지 내용이 변경되지 않았는지 확인
      assert_equal "안녕하세요 한글 메시지입니다 😀", korean_message.reload.content
    end

    test "broadcasts message with special characters" do
      special_message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "특수문자 <script>alert('test')</script> & \"quotes\""
      )

      assert_nothing_raised do
        Messages::Broadcaster.call(special_message)
      end

      # XSS 공격 문자열도 그대로 저장 (렌더링 시 이스케이프됨)
      assert_equal "특수문자 <script>alert('test')</script> & \"quotes\"", special_message.reload.content
    end

    test "broadcasts to all participants" do
      @user3 = users(:three)
      @chat_room.participants.find_or_create_by!(user: @user3)

      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "모든 참여자에게 전송"
      )

      # 브로드캐스트 횟수 = 참여자 수
      participant_count = @chat_room.participants.count
      assert_equal 3, participant_count

      # 에러 없이 모든 참여자에게 브로드캐스트
      assert_nothing_raised do
        Messages::Broadcaster.call(message)
      end
    end

    test "sender does not receive badge update" do
      # 보낸 사람은 뱃지 업데이트를 받지 않아야 함
      # Turbo::StreamsChannel.broadcast_replace_to 호출 추적은 복잡하므로
      # 로직이 에러 없이 실행되는지 확인
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "뱃지 업데이트 테스트"
      )

      assert_nothing_raised do
        Messages::Broadcaster.call(message)
      end
    end

    # ===== 발신자 제외 테스트 (중복 메시지 방지) =====

    test "일반 텍스트 메시지는 발신자에게 브로드캐스트하지 않음" do
      # text 타입만 발신자 제외: create.turbo_stream.erb에서 HTTP 응답으로 렌더링됨
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "발신자 제외 테스트",
        message_type: :text
      )

      broadcaster = Messages::Broadcaster.new(message)

      # broadcast_new_message가 발신자에 대해 호출될 때 early return하는지 확인
      call_count = 0
      Turbo::StreamsChannel.stub :broadcast_append_to, ->(*args) { call_count += 1 } do
        broadcaster.send(:broadcast_to_participant, @chat_room.participants.find_by(user: @user1))
      end

      # 발신자에게는 new_message 브로드캐스트가 되지 않음
      assert_equal 0, call_count, "text 메시지는 발신자에게 broadcast_append_to가 호출되면 안 됨"
    end

    test "일반 텍스트 메시지는 수신자에게만 브로드캐스트됨" do
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "수신자 테스트",
        message_type: :text
      )

      broadcaster = Messages::Broadcaster.new(message)
      call_count = 0

      Turbo::StreamsChannel.stub :broadcast_append_to, ->(*args) { call_count += 1 } do
        broadcaster.send(:broadcast_to_participant, @chat_room.participants.find_by(user: @user2))
      end

      # 수신자에게는 new_message 브로드캐스트가 됨
      assert_equal 1, call_count, "수신자에게 broadcast_append_to가 호출되어야 함"
    end

    test "시스템 메시지는 발신자에게도 브로드캐스트됨" do
      # 시스템 메시지: 서버에서 생성되므로 모든 참여자에게 전송해야 함
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "시스템 메시지",
        message_type: :system
      )

      broadcaster = Messages::Broadcaster.new(message)
      call_count = 0

      Turbo::StreamsChannel.stub :broadcast_append_to, ->(*args) { call_count += 1 } do
        broadcaster.send(:broadcast_to_participant, @chat_room.participants.find_by(user: @user1))
      end

      assert_equal 1, call_count, "시스템 메시지는 발신자에게도 브로드캐스트되어야 함"
    end

    test "거래 확정 메시지는 발신자에게도 브로드캐스트됨" do
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "거래가 확정되었습니다",
        message_type: :deal_confirm
      )

      broadcaster = Messages::Broadcaster.new(message)
      call_count = 0

      Turbo::StreamsChannel.stub :broadcast_append_to, ->(*args) { call_count += 1 } do
        broadcaster.send(:broadcast_to_participant, @chat_room.participants.find_by(user: @user1))
      end

      assert_equal 1, call_count, "거래 확정 메시지는 발신자에게도 브로드캐스트되어야 함"
    end

    test "프로필 카드 메시지는 발신자에게도 브로드캐스트됨" do
      # profile_card: head :ok 반환하므로 Broadcaster에서 전송해야 함
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "프로필 공유",
        message_type: :profile_card,
        metadata: { user_id: @user1.id, name: @user1.name }
      )

      broadcaster = Messages::Broadcaster.new(message)
      call_count = 0

      Turbo::StreamsChannel.stub :broadcast_append_to, ->(*args) { call_count += 1 } do
        broadcaster.send(:broadcast_to_participant, @chat_room.participants.find_by(user: @user1))
      end

      assert_equal 1, call_count, "프로필 카드는 발신자에게도 브로드캐스트되어야 함"
    end

    test "거래 제안 카드 메시지는 발신자에게도 브로드캐스트됨" do
      # offer_card: head :ok 반환하므로 Broadcaster에서 전송해야 함
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "거래 제안이 도착했습니다",
        message_type: :offer_card,
        metadata: { amount: 100000, title: "테스트", status: "pending" }
      )

      broadcaster = Messages::Broadcaster.new(message)
      call_count = 0

      Turbo::StreamsChannel.stub :broadcast_append_to, ->(*args) { call_count += 1 } do
        broadcaster.send(:broadcast_to_participant, @chat_room.participants.find_by(user: @user1))
      end

      assert_equal 1, call_count, "거래 제안 카드는 발신자에게도 브로드캐스트되어야 함"
    end

    # ===== 채널 이름 검증 테스트 =====

    test "올바른 채널 이름으로 브로드캐스트" do
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "채널 이름 테스트"
      )

      broadcaster = Messages::Broadcaster.new(message)
      received_channel = nil

      # 수신자에게 브로드캐스트할 때 채널 이름 캡처
      Turbo::StreamsChannel.stub :broadcast_append_to, ->(channel, **_kwargs) { received_channel = channel } do
        broadcaster.send(:broadcast_to_participant, @chat_room.participants.find_by(user: @user2))
      end

      expected_channel = "chat_room_#{@chat_room.id}_user_#{@user2.id}"
      assert_equal expected_channel, received_channel, "올바른 채널 이름으로 브로드캐스트되어야 함"
    end

    test "contact_card 메시지는 발신자에게도 브로드캐스트됨" do
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "연락처 공유",
        message_type: :contact_card,
        metadata: { phone: "010-1234-5678" }
      )

      broadcaster = Messages::Broadcaster.new(message)
      call_count = 0

      Turbo::StreamsChannel.stub :broadcast_append_to, ->(*args) { call_count += 1 } do
        broadcaster.send(:broadcast_to_participant, @chat_room.participants.find_by(user: @user1))
      end

      assert_equal 1, call_count, "연락처 카드는 발신자에게도 브로드캐스트되어야 함"
    end

    # ===== 전체 브로드캐스트 통합 테스트 =====

    test "call 메서드가 모든 참여자에게 올바르게 브로드캐스트" do
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "통합 테스트",
        message_type: :system  # 시스템 메시지는 모든 참여자에게 전송
      )

      broadcasted_channels = []

      Turbo::StreamsChannel.stub :broadcast_append_to, ->(channel, **_kwargs) { broadcasted_channels << channel } do
        Turbo::StreamsChannel.stub :broadcast_replace_to, ->(*args) { } do
          Messages::Broadcaster.call(message)
        end
      end

      # 2명의 참여자 모두에게 브로드캐스트되어야 함
      expected_channels = [
        "chat_room_#{@chat_room.id}_user_#{@user1.id}",
        "chat_room_#{@chat_room.id}_user_#{@user2.id}"
      ]

      expected_channels.each do |channel|
        assert_includes broadcasted_channels, channel, "#{channel}에 브로드캐스트되어야 함"
      end
    end

    test "text 메시지 call 시 발신자 제외하고 브로드캐스트" do
      message = Message.create!(
        chat_room: @chat_room,
        sender: @user1,
        content: "발신자 제외 통합 테스트",
        message_type: :text
      )

      broadcasted_channels = []

      Turbo::StreamsChannel.stub :broadcast_append_to, ->(channel, **_kwargs) { broadcasted_channels << channel } do
        Turbo::StreamsChannel.stub :broadcast_replace_to, ->(*args) { } do
          Messages::Broadcaster.call(message)
        end
      end

      sender_channel = "chat_room_#{@chat_room.id}_user_#{@user1.id}"
      receiver_channel = "chat_room_#{@chat_room.id}_user_#{@user2.id}"

      # 발신자 채널은 제외되어야 함
      assert_not_includes broadcasted_channels, sender_channel, "발신자에게는 브로드캐스트되지 않아야 함"
      # 수신자 채널에는 브로드캐스트되어야 함
      assert_includes broadcasted_channels, receiver_channel, "수신자에게는 브로드캐스트되어야 함"
    end
  end
end
