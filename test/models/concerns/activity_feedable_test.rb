# frozen_string_literal: true

require "test_helper"

class ActivityFeedableTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  # =========================================
  # recent_activities 메서드 테스트
  # =========================================

  test "recent_activities returns array" do
    result = @user.recent_activities

    assert_kind_of Array, result
  end

  test "recent_activities respects limit parameter" do
    result = @user.recent_activities(limit: 5)

    assert result.length <= 5
  end

  test "recent_activities default limit is 20" do
    result = @user.recent_activities

    assert result.length <= 20
  end

  test "recent_activities includes posts and comments" do
    # 활동이 있는 경우 테스트
    result = @user.recent_activities(limit: 50)

    # 결과가 있으면 Post 또는 Comment 타입이어야 함
    result.each do |activity|
      assert activity.is_a?(Post) || activity.is_a?(Comment),
             "Expected Post or Comment, got #{activity.class}"
    end
  end

  test "recent_activities ordered by created_at desc" do
    result = @user.recent_activities

    if result.length > 1
      # 최신순 정렬 확인
      result.each_cons(2) do |newer, older|
        assert newer.created_at >= older.created_at,
               "Activities should be ordered by created_at desc"
      end
    end
  end

  test "recent_activities returns empty array when no activities" do
    # 활동이 없는 새 사용자
    new_user = User.create!(
      email: "newuser_#{SecureRandom.hex(4)}@example.com",
      name: "New User",
      password: "password123"
    )

    result = new_user.recent_activities

    assert_equal [], result
  end
end
