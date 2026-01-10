# frozen_string_literal: true

# DatabaseBackupJob
#
# ⚠️ DEPRECATED in Production (PostgreSQL 환경)
# Production에서 PostgreSQL 사용 시 이 Job은 비활성화됩니다.
# DigitalOcean Managed Database의 자동 백업을 사용하세요.
#
# SQLite 환경 (Development)에서만 사용:
#   DatabaseBackupJob.perform_later
#   bin/rails backup:database
#
# 활성화하려면 config/recurring.yml에서 database_backup 주석 해제
#
class DatabaseBackupJob < ApplicationJob
  queue_as :default

  # Retry on failure with exponential backoff
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform
    Rails.logger.info "[DatabaseBackupJob] Starting database backup..."

    # Load rake tasks (required in Solid Queue job context)
    Rails.application.load_tasks

    # Run the backup rake task
    Rake::Task["backup:database"].reenable
    Rake::Task["backup:database"].invoke

    Rails.logger.info "[DatabaseBackupJob] Database backup completed"
  rescue StandardError => e
    Rails.logger.error "[DatabaseBackupJob] Backup failed: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")

    # Report to Sentry if available
    Sentry.capture_exception(e) if defined?(Sentry)

    raise # Re-raise for retry mechanism
  end
end
