# frozen_string_literal: true

# 푸시 알림 전송 백그라운드 Job
#
# 푸시 알림 전송을 비동기로 처리하여 메인 요청 응답 속도에 영향을 주지 않습니다.
# 재시도 로직과 에러 핸들링 포함.
#
# @example 단일 사용자에게 전송
#   SendPushNotificationJob.perform_later(
#     user_id: user.id,
#     title: "새 메시지",
#     body: "홍길동님이 메시지를 보냈습니다.",
#     data: { chat_room_id: "123", type: "message" }
#   )
#
# @example Notification 모델과 연동
#   SendPushNotificationJob.perform_later(notification_id: notification.id)
#
class SendPushNotificationJob < ApplicationJob
  queue_as :push_notifications

  # 재시도 설정 (최대 3회, 지수 백오프)
  retry_on PushNotifications::FcmService::FcmError, wait: :polynomially_longer, attempts: 3
  retry_on Faraday::Error, wait: 5.seconds, attempts: 3

  # Rate limit 초과 시 더 긴 대기 후 재시도
  retry_on PushNotifications::FcmService::QuotaExceededError, wait: 1.minute, attempts: 5

  # 폐기 조건 (더 이상 재시도하지 않음)
  discard_on ActiveRecord::RecordNotFound

  # 메인 실행 메서드
  #
  # @param user_id [Integer] 대상 사용자 ID (옵션 1)
  # @param notification_id [Integer] Notification 레코드 ID (옵션 2)
  # @param title [String] 알림 제목
  # @param body [String] 알림 본문
  # @param data [Hash] 추가 데이터
  def perform(user_id: nil, notification_id: nil, title: nil, body: nil, data: {})
    if notification_id.present?
      send_from_notification(notification_id)
    elsif user_id.present?
      send_to_user(user_id: user_id, title: title, body: body, data: data)
    else
      Rails.logger.error "[PushNotification] Missing user_id or notification_id"
    end
  end

  private

  # Notification 레코드 기반 전송
  def send_from_notification(notification_id)
    notification = Notification.find(notification_id)
    user = notification.recipient

    # 알림 비활성화한 사용자 스킵 (향후 기능 추가 대비)
    return if user.respond_to?(:push_notifications_disabled?) && user.push_notifications_disabled?

    title, body = build_notification_content(notification)
    data = {
      type: notification.notification_type,
      notifiable_type: notification.notifiable_type,
      notifiable_id: notification.notifiable_id.to_s,
      notification_id: notification.id.to_s
    }

    send_to_user(user_id: user.id, title: title, body: body, data: data)
  end

  # 사용자에게 직접 전송
  def send_to_user(user_id:, title:, body:, data:)
    user = User.find(user_id)
    fcm_service = PushNotifications::FcmService.new

    unless fcm_service.configured?
      Rails.logger.info "[PushNotification] FCM not configured, skipping"
      return
    end

    results = fcm_service.send_to_user(
      user: user,
      title: title,
      body: body,
      data: data
    )

    log_results(user_id, results)
  end

  # Notification 타입별 제목/본문 생성
  def build_notification_content(notification)
    actor_name = notification.actor&.display_name || "누군가"

    case notification.notification_type
    when "comment"
      [ "새 댓글", "#{actor_name}님이 댓글을 남겼습니다." ]
    when "reply"
      [ "답글 알림", "#{actor_name}님이 답글을 남겼습니다." ]
    when "like"
      [ "좋아요", "#{actor_name}님이 회원님의 게시글을 좋아합니다." ]
    when "message"
      [ "새 메시지", "#{actor_name}님이 메시지를 보냈습니다." ]
    when "mention"
      [ "멘션", "#{actor_name}님이 회원님을 언급했습니다." ]
    when "follow"
      [ "새 팔로워", "#{actor_name}님이 회원님을 팔로우합니다." ]
    else
      [ "알림", "새로운 알림이 있습니다." ]
    end
  end

  # 전송 결과 로깅
  def log_results(user_id, results)
    success_count = results.count { |r| r[:success] }
    fail_count = results.count { |r| !r[:success] }

    if fail_count.zero?
      Rails.logger.info "[PushNotification] User##{user_id}: Sent to #{success_count} device(s)"
    else
      Rails.logger.warn "[PushNotification] User##{user_id}: #{success_count} success, #{fail_count} failed"
      results.each do |result|
        next if result[:success]

        Rails.logger.warn "[PushNotification] Device##{result[:device_id]} failed: #{result[:error]}"
      end
    end
  end
end
