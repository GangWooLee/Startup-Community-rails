# frozen_string_literal: true

# n8n Webhook 호출 Job
# 회원가입 시 구글시트 자동 동기화용
#
# 사용법:
#   NotifyN8nWebhookJob.perform_later(user_id, "user_created")
#
# 필수 설정:
#   Rails credentials에 n8n.webhook_url 추가
#   rails credentials:edit → n8n: { webhook_url: "https://..." }
#
class NotifyN8nWebhookJob < ApplicationJob
  queue_as :default

  # 재시도 설정: 네트워크 오류 시 3회까지 재시도
  retry_on Faraday::Error, wait: :polynomially_longer, attempts: 3

  def perform(user_id, event_type = "user_created")
    user = User.find_by(id: user_id)
    return unless user

    webhook_url = Rails.application.credentials.dig(:n8n, :webhook_url)
    return if webhook_url.blank?

    payload = build_payload(user, event_type)

    response = Faraday.post(webhook_url) do |req|
      req.headers["Content-Type"] = "application/json"
      req.options.timeout = 10       # 읽기 타임아웃 10초
      req.options.open_timeout = 5   # 연결 타임아웃 5초
      req.body = payload.to_json
    end

    Rails.logger.info "[N8N Webhook] #{event_type} - User##{user_id} - Status: #{response.status}"
  rescue StandardError => e
    Rails.logger.error "[N8N Webhook] Error: #{e.class} - #{e.message}"
    Sentry.capture_exception(e) if defined?(Sentry)
  end

  private

  def build_payload(user, event_type)
    {
      event: event_type,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        nickname: user.nickname,
        created_at: user.created_at.iso8601
      },
      timestamp: Time.current.iso8601
    }
  end
end
