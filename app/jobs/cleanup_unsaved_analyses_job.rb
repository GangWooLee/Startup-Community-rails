# 미저장 분석 결과 자동 삭제 Job
# - 사용자가 저장하지 않은 분석 결과를 30분 후 자동 삭제
# - 30분마다 실행 (config/recurring.yml)
class CleanupUnsavedAnalysesJob < ApplicationJob
  queue_as :default

  def perform
    deleted_count = 0
    error_count = 0

    IdeaAnalysis.expired_unsaved.find_each do |analysis|
      Rails.logger.info "[CleanupUnsavedAnalyses] Deleting IdeaAnalysis ##{analysis.id} (User ##{analysis.user_id})"
      analysis.destroy!
      deleted_count += 1
    rescue StandardError => e
      Rails.logger.error "[CleanupUnsavedAnalyses] Failed to delete ##{analysis.id}: #{e.message}"
      error_count += 1
    end

    Rails.logger.info "[CleanupUnsavedAnalyses] Completed: #{deleted_count} deleted, #{error_count} errors"

    { deleted: deleted_count, errors: error_count }
  end
end
