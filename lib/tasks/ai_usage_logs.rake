# frozen_string_literal: true

namespace :ai_usage_logs do
  desc "기존 IdeaAnalysis 레코드에서 AiUsageLog 백필 생성"
  task backfill: :environment do
    puts "Starting AiUsageLog backfill..."

    total_count = IdeaAnalysis.count
    created_count = 0
    skipped_count = 0
    error_count = 0

    IdeaAnalysis.find_each.with_index do |analysis, index|
      # 이미 로그가 있으면 스킵
      if AiUsageLog.exists?(idea_analysis_id: analysis.id)
        skipped_count += 1
        next
      end

      AiUsageLog.create!(
        user_id: analysis.user_id,
        idea_summary: analysis.idea.to_s.truncate(200),
        status: analysis.status,
        is_real_analysis: analysis.is_real_analysis,
        score: analysis.score,
        completed_at: analysis.completed? ? analysis.updated_at : nil,
        idea_analysis_id: analysis.id,
        was_saved: analysis.is_saved,
        created_at: analysis.created_at,
        updated_at: analysis.updated_at
      )
      created_count += 1

      # 진행률 표시 (100개마다)
      if (index + 1) % 100 == 0
        puts "Progress: #{index + 1}/#{total_count}"
      end
    rescue StandardError => e
      error_count += 1
      puts "Error for IdeaAnalysis##{analysis.id}: #{e.message}"
    end

    puts "\n" + "=" * 50
    puts "Backfill completed!"
    puts "Total IdeaAnalysis: #{total_count}"
    puts "Created: #{created_count}"
    puts "Skipped (already exists): #{skipped_count}"
    puts "Errors: #{error_count}"
    puts "=" * 50
  end

  desc "AiUsageLog 통계 확인"
  task stats: :environment do
    puts "\n" + "=" * 60
    puts "AiUsageLog Statistics"
    puts "=" * 60

    stats = AiUsageLog.usage_stats

    puts "\n[전체 현황]"
    puts "총 사용 기록: #{stats[:total]}건"
    puts "오늘: #{stats[:today]}건"
    puts "이번 주: #{stats[:this_week]}건"
    puts "이번 달: #{stats[:this_month]}건"

    puts "\n[분석 유형]"
    puts "실제 AI 분석: #{stats[:real_analyses]}건"
    puts "Mock 분석: #{stats[:mock_analyses]}건"

    puts "\n[상태별]"
    puts "완료: #{stats[:completed]}건"
    puts "실패: #{stats[:failed]}건"
    puts "사용자 저장: #{stats[:saved_by_user]}건"

    puts "\n[IdeaAnalysis 비교]"
    puts "IdeaAnalysis 총 수: #{IdeaAnalysis.count}건"
    puts "AiUsageLog 중 원본 존재: #{AiUsageLog.where.not(idea_analysis_id: nil).count}건"
    puts "AiUsageLog 중 원본 삭제됨: #{AiUsageLog.where(idea_analysis_id: nil).count}건"

    puts "\n" + "=" * 60
  end
end
