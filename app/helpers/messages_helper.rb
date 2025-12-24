module MessagesHelper
  # 메시지 그룹화 정보 계산
  # 같은 사용자가 1분 이내에 연속 전송한 메시지는 그룹으로 묶음
  # 프로필은 그룹의 첫 번째 메시지에만, 시간은 마지막 메시지에만 표시

  GROUPING_THRESHOLD = 1.minute

  # 메시지가 그룹의 첫 번째인지 확인 (프로필 표시 여부)
  # prev_message: 이전 메시지 (없으면 nil)
  # current_message: 현재 메시지
  def message_is_first_in_group?(prev_message, current_message)
    return true if prev_message.nil?
    return true if prev_message.sender_id != current_message.sender_id
    return true if (current_message.created_at - prev_message.created_at) > GROUPING_THRESHOLD
    # 시스템 메시지는 항상 그룹 분리
    return true if prev_message.system? || prev_message.deal_confirm?
    return true if current_message.system? || current_message.deal_confirm?

    false
  end

  # 메시지가 그룹의 마지막인지 확인 (시간 표시 여부)
  # current_message: 현재 메시지
  # next_message: 다음 메시지 (없으면 nil)
  def message_is_last_in_group?(current_message, next_message)
    return true if next_message.nil?
    return true if current_message.sender_id != next_message.sender_id
    return true if (next_message.created_at - current_message.created_at) > GROUPING_THRESHOLD
    # 시스템 메시지는 항상 그룹 분리
    return true if current_message.system? || current_message.deal_confirm?
    return true if next_message.system? || next_message.deal_confirm?

    false
  end

  # 날짜 구분선이 필요한지 확인
  # prev_message: 이전 메시지 (없으면 nil)
  # current_message: 현재 메시지
  def needs_date_divider?(prev_message, current_message)
    return true if prev_message.nil?

    prev_message.created_at.to_date != current_message.created_at.to_date
  end

  # 날짜 포맷팅 (한국어)
  # 오늘 → "오늘", 어제 → "어제", 그 외 → "YYYY/MM/DD"
  def format_message_date(date)
    if date.today?
      "오늘"
    elsif date.yesterday?
      "어제"
    else
      date.strftime("%Y/%m/%d")
    end
  end

  # 메시지 시간 포맷팅 (한국 시간대 적용)
  # timestamp: ActiveSupport::TimeWithZone 또는 Time 객체
  def format_message_time(timestamp)
    timestamp.in_time_zone("Seoul").strftime("%H:%M")
  end

  # 메시지 읽음 상태 확인
  # 상대방이 이 메시지를 읽었는지 확인
  # message: 확인할 메시지
  # other_participant: 상대방의 ChatRoomParticipant
  def message_read_by_other?(message, other_participant)
    return true if other_participant.nil?
    return true unless message.sender_id == message.chat_room.participants.find_by(user_id: message.sender_id)&.user_id

    other_last_read = other_participant.last_read_at
    return false if other_last_read.nil?

    message.created_at <= other_last_read
  end

  # 내 메시지 중 상대방이 읽지 않은 개수
  def unread_count_for_sender(messages, sender_id, other_participant)
    return 0 if other_participant.nil?

    other_last_read = other_participant.last_read_at || Time.at(0)

    messages.count do |msg|
      msg.sender_id == sender_id && msg.created_at > other_last_read
    end
  end
end
