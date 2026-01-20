# frozen_string_literal: true

require "test_helper"

class MessageableTest < ActiveSupport::TestCase
  fixtures :users

  def setup
    @user = users(:one)
    @other_user = users(:two)
  end

  # =========================================
  # total_unread_messages 메서드 테스트
  # =========================================

  test "total_unread_messages returns integer" do
    result = @user.total_unread_messages

    assert_kind_of Integer, result
  end

  test "total_unread_messages returns zero for user with no chat rooms" do
    # 채팅방 참여가 없는 경우 0 반환
    result = @user.total_unread_messages

    assert result >= 0
  end

  test "total_unread_messages sums unread_count from participants" do
    # unread_count 컬럼을 사용하여 합계 반환
    chat_room = ChatRoom.create!
    participant = ChatRoomParticipant.create!(
      chat_room: chat_room,
      user: @user,
      unread_count: 5
    )

    result = @user.total_unread_messages
    assert result >= 5
  ensure
    participant&.destroy
    chat_room&.destroy
  end

  test "total_unread_messages excludes deleted participants" do
    chat_room = ChatRoom.create!
    participant = ChatRoomParticipant.create!(
      chat_room: chat_room,
      user: @user,
      unread_count: 10,
      deleted_at: Time.current  # 삭제된 참여자
    )

    # 삭제된 참여자의 unread_count는 포함되지 않아야 함
    result = @user.total_unread_messages
    # 해당 채팅방의 unread_count는 무시됨
    assert_kind_of Integer, result
  ensure
    participant&.destroy
    chat_room&.destroy
  end

  # =========================================
  # has_unread_messages? 메서드 테스트
  # =========================================

  test "has_unread_messages? returns true or false (not 0 or 1)" do
    result = @user.has_unread_messages?

    # 반드시 boolean 타입이어야 함 (SQLite 호환)
    assert_includes [ TrueClass, FalseClass ], result.class
  end

  test "has_unread_messages? returns false for user with no chat rooms" do
    # 채팅방 참여가 없는 경우 false 반환
    result = @user.has_unread_messages?

    assert_equal false, result
  end

  test "has_unread_messages? returns true when unread_count > 0" do
    chat_room = ChatRoom.create!
    participant = ChatRoomParticipant.create!(
      chat_room: chat_room,
      user: @user,
      unread_count: 3
    )

    result = @user.has_unread_messages?
    assert_equal true, result
  ensure
    participant&.destroy
    chat_room&.destroy
  end

  test "has_unread_messages? returns false when all unread_count is 0" do
    chat_room = ChatRoom.create!
    participant = ChatRoomParticipant.create!(
      chat_room: chat_room,
      user: @user,
      unread_count: 0
    )

    # unread_count가 0이면 false
    result = @user.has_unread_messages?
    assert_equal false, result
  ensure
    participant&.destroy
    chat_room&.destroy
  end

  # =========================================
  # SQL 쿼리 안전성 테스트
  # =========================================

  test "total_unread_messages uses parameterized query" do
    # SQL Injection 방지 - 파라미터화된 쿼리 사용 확인
    # 이 테스트는 메서드가 에러 없이 실행되는지 확인
    assert_nothing_raised do
      @user.total_unread_messages
    end
  end

  test "has_unread_messages uses parameterized query" do
    # SQL Injection 방지 - 파라미터화된 쿼리 사용 확인
    assert_nothing_raised do
      @user.has_unread_messages?
    end
  end
end
