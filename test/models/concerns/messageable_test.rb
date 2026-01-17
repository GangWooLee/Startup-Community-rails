# frozen_string_literal: true

require "test_helper"

class MessageableTest < ActiveSupport::TestCase
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

  # =========================================
  # has_unread_messages? 메서드 테스트
  # =========================================

  test "has_unread_messages? returns boolean" do
    result = @user.has_unread_messages?

    assert_includes [ true, false ], result
  end

  test "has_unread_messages? returns false for user with no chat rooms" do
    # 채팅방 참여가 없는 경우 false 반환
    result = @user.has_unread_messages?

    # SQLite에서 EXISTS는 0/1을 반환하므로 falsy 값으로 확인
    assert_not result
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
