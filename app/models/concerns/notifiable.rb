# frozen_string_literal: true

# 알림 관련 메서드
# User 모델에서 추출된 concern
module Notifiable
  extend ActiveSupport::Concern

  # 읽지 않은 알림 수
  def unread_notifications_count
    notifications.unread.count
  end

  # 읽지 않은 알림이 있는지 확인
  def has_unread_notifications?
    notifications.unread.exists?
  end
end
