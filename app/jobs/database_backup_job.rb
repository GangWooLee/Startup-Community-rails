# frozen_string_literal: true

# DatabaseBackupJob
#
# Runs daily at 4am KST to backup SQLite databases to S3.
# Configured in config/recurring.yml for Solid Queue.
#
# Manual execution:
#   DatabaseBackupJob.perform_later
#   bin/rails backup:database
#
class DatabaseBackupJob < ApplicationJob
  queue_as :default

  # Retry on failure with exponential backoff
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform
    Rails.logger.info "[DatabaseBackupJob] Starting database backup..."

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
