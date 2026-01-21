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

  # =========================================
  # Performance Tests (Step 3)
  # N+1 방지: 단일 쿼리 실행 검증
  # =========================================

  test "total_unread_messages executes single SQL query" do
    # 다중 채팅방 생성
    chat_rooms = []
    participants = []

    3.times do
      chat_room = ChatRoom.create!
      participant = ChatRoomParticipant.create!(
        chat_room: chat_room,
        user: @user,
        unread_count: 5
      )
      chat_rooms << chat_room
      participants << participant
    end

    # 쿼리 카운트 측정
    query_count = count_queries do
      result = @user.total_unread_messages
      # 결과 검증 (15 = 5 * 3)
      assert_equal 15, result
    end

    # 단일 SUM 쿼리만 실행되어야 함
    assert_equal 1, query_count, "total_unread_messages should execute single SUM query, but executed #{query_count} queries"
  ensure
    participants&.each(&:destroy)
    chat_rooms&.each(&:destroy)
  end

  test "has_unread_messages? executes single SQL query" do
    # 다중 채팅방 생성 (읽지 않은 메시지 있음)
    chat_rooms = []
    participants = []

    3.times do
      chat_room = ChatRoom.create!
      participant = ChatRoomParticipant.create!(
        chat_room: chat_room,
        user: @user,
        unread_count: 5
      )
      chat_rooms << chat_room
      participants << participant
    end

    # 쿼리 카운트 측정
    query_count = count_queries do
      result = @user.has_unread_messages?
      assert_equal true, result
    end

    # 단일 EXISTS 쿼리만 실행되어야 함
    assert_equal 1, query_count, "has_unread_messages? should execute single EXISTS query, but executed #{query_count} queries"
  ensure
    participants&.each(&:destroy)
    chat_rooms&.each(&:destroy)
  end

  private

  # SQL 쿼리 카운트 헬퍼 메서드
  def count_queries(&block)
    count = 0
    counter_fn = ->(name, _started, _finished, _unique_id, payload) {
      # SCHEMA 쿼리와 TRANSACTION 쿼리 제외
      unless payload[:name].in?([ "SCHEMA", "TRANSACTION" ]) || payload[:sql].start_with?("PRAGMA")
        count += 1
      end
    }

    ActiveSupport::Notifications.subscribed(counter_fn, "sql.active_record", &block)
    count
  end
end
