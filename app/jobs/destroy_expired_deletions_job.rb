# 만료된 탈퇴 기록 자동 파기 Job
# - 법적 보관 기간(5년) 경과 후 자동 삭제
# - 매일 새벽 3시에 실행 (config/recurring.yml)
class DestroyExpiredDeletionsJob < ApplicationJob
  queue_as :default

  def perform
    expired_count = 0
    error_count = 0

    UserDeletion.expired.find_each do |deletion|
      begin
        Rails.logger.info "[AutoDestroy] Destroying UserDeletion ##{deletion.id} (User ##{deletion.user_id})"
        deletion.destroy!
        expired_count += 1
      rescue StandardError => e
        Rails.logger.error "[AutoDestroy] Failed to destroy ##{deletion.id}: #{e.message}"
        error_count += 1
      end
    end

    Rails.logger.info "[AutoDestroy] Completed: #{expired_count} destroyed, #{error_count} errors"

    { destroyed: expired_count, errors: error_count }
  end
end
