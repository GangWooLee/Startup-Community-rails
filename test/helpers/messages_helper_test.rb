require "test_helper"

class MessagesHelperTest < ActionView::TestCase
  include MessagesHelper

  # 메시지 그룹화 테스트

  test "message_is_first_in_group returns true for first message" do
    message = Message.new(sender_id: 1, created_at: Time.current)
    assert message_is_first_in_group?(nil, message)
  end

  test "message_is_first_in_group returns true when sender changes" do
    prev_message = Message.new(sender_id: 1, created_at: Time.current)
    current_message = Message.new(sender_id: 2, created_at: Time.current)
    assert message_is_first_in_group?(prev_message, current_message)
  end

  test "message_is_first_in_group returns true when time gap exceeds threshold" do
    prev_message = Message.new(sender_id: 1, created_at: 2.minutes.ago)
    current_message = Message.new(sender_id: 1, created_at: Time.current)
    assert message_is_first_in_group?(prev_message, current_message)
  end

  test "message_is_first_in_group returns false for consecutive messages within threshold" do
    prev_message = Message.new(sender_id: 1, created_at: 30.seconds.ago)
    current_message = Message.new(sender_id: 1, created_at: Time.current)
    refute message_is_first_in_group?(prev_message, current_message)
  end

  test "message_is_last_in_group returns true for last message" do
    message = Message.new(sender_id: 1, created_at: Time.current)
    assert message_is_last_in_group?(message, nil)
  end

  test "message_is_last_in_group returns true when sender changes" do
    current_message = Message.new(sender_id: 1, created_at: Time.current)
    next_message = Message.new(sender_id: 2, created_at: Time.current)
    assert message_is_last_in_group?(current_message, next_message)
  end

  test "message_is_last_in_group returns false for consecutive messages within threshold" do
    current_message = Message.new(sender_id: 1, created_at: Time.current)
    next_message = Message.new(sender_id: 1, created_at: 30.seconds.from_now)
    refute message_is_last_in_group?(current_message, next_message)
  end

  # 날짜 구분선 테스트

  test "needs_date_divider returns true for first message" do
    message = Message.new(created_at: Time.current)
    assert needs_date_divider?(nil, message)
  end

  test "needs_date_divider returns true when date changes" do
    prev_message = Message.new(created_at: 1.day.ago)
    current_message = Message.new(created_at: Time.current)
    assert needs_date_divider?(prev_message, current_message)
  end

  test "needs_date_divider returns false for same day messages" do
    today = Time.current.beginning_of_day + 12.hours
    prev_message = Message.new(created_at: today)
    current_message = Message.new(created_at: today + 1.hour)
    refute needs_date_divider?(prev_message, current_message)
  end

  # 날짜 포맷팅 테스트

  test "format_message_date returns '오늘' for today" do
    assert_equal "오늘", format_message_date(Date.current)
  end

  test "format_message_date returns '어제' for yesterday" do
    assert_equal "어제", format_message_date(Date.yesterday)
  end

  test "format_message_date returns YYYY/MM/DD for dates before yesterday" do
    # 1주일 전
    date = Date.current - 7.days
    result = format_message_date(date)
    # "2025/12/17" 형식
    assert_match(/\d{4}\/\d{2}\/\d{2}/, result)
    assert_equal date.strftime("%Y/%m/%d"), result
  end

  test "format_message_date returns YYYY/MM/DD for previous year" do
    date = Date.new(Date.current.year - 1, 12, 25)
    result = format_message_date(date)
    # "2024/12/25" 형식
    assert_equal "#{date.year}/12/25", result
  end

  test "format_message_date returns YYYY/MM/DD for one month ago" do
    date = Date.current - 30.days
    result = format_message_date(date)
    assert_equal date.strftime("%Y/%m/%d"), result
  end

  # 시간 포맷팅 테스트

  test "format_message_time returns time in Seoul timezone" do
    # UTC 기준 02:30 = 한국 시간 11:30
    utc_time = Time.utc(2025, 12, 24, 2, 30, 0)
    result = format_message_time(utc_time)
    assert_equal "11:30", result
  end

  test "format_message_time handles midnight correctly" do
    # UTC 기준 15:00 = 한국 시간 00:00 (다음날)
    utc_time = Time.utc(2025, 12, 24, 15, 0, 0)
    result = format_message_time(utc_time)
    assert_equal "00:00", result
  end
end
