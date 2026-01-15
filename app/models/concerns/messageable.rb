# frozen_string_literal: true

# 메시지/채팅 관련 메서드
# User 모델에서 추출된 concern
module Messageable
  extend ActiveSupport::Concern

  # 읽지 않은 메시지 총 수 (N+1 방지: 단일 SQL 쿼리)
  def total_unread_messages
    sql = <<~SQL
      SELECT COUNT(*)
      FROM messages m
      INNER JOIN chat_room_participants crp
        ON crp.chat_room_id = m.chat_room_id
      WHERE crp.user_id = ?
        AND crp.deleted_at IS NULL
        AND m.sender_id != ?
        AND m.created_at > COALESCE(crp.last_read_at, '1970-01-01')
    SQL

    ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql([ sql, id, id ])
    ).to_i
  end

  # 읽지 않은 메시지가 있는지 확인 (EXISTS로 최적화 - COUNT보다 빠름)
  def has_unread_messages?
    sql = <<~SQL
      SELECT EXISTS(
        SELECT 1
        FROM messages m
        INNER JOIN chat_room_participants crp
          ON crp.chat_room_id = m.chat_room_id
        WHERE crp.user_id = ?
          AND crp.deleted_at IS NULL
          AND m.sender_id != ?
          AND m.created_at > COALESCE(crp.last_read_at, '1970-01-01')
        LIMIT 1
      )
    SQL

    ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql([ sql, id, id ])
    ) == 1
  end
end
