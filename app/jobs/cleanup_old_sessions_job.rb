# frozen_string_literal: true

# 오래된 세션 기록 자동 삭제 Job
# - 90일 경과 후 자동 삭제
# - 매일 새벽 3시 30분에 실행 (config/recurring.yml)
# - 프라이버시 보호 + 스토리지 관리 목적
class CleanupOldSessionsJob < ApplicationJob
  queue_as :default

  RETENTION_DAYS = 90

  def perform
    cutoff_date = RETENTION_DAYS.days.ago

    # 배치 삭제 (대량 데이터 처리 시 메모리 효율)
    deleted_count = UserSession.where("logged_in_at < ?", cutoff_date).delete_all

    Rails.logger.info "[SessionCleanup] Deleted #{deleted_count} sessions older than #{RETENTION_DAYS} days"

    { deleted: deleted_count, retention_days: RETENTION_DAYS }
  end
end
