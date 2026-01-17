# AI 분석 사용 기록 (영구 보존)
# - IdeaAnalysis가 삭제되어도 사용 기록은 유지됨
# - 통계 및 사용량 추적 목적
class CreateAiUsageLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_usage_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.text :idea_summary                           # 아이디어 요약 (첫 200자)
      t.string :status, default: "analyzing"         # analyzing, completed, failed
      t.boolean :is_real_analysis, default: true     # 실제 AI 분석 vs Mock
      t.integer :score                               # 분석 점수 (완료 시)
      t.datetime :completed_at                       # 분석 완료 시점
      t.integer :idea_analysis_id                    # 원본 분석 ID (삭제 후 NULL 가능)
      t.boolean :was_saved, default: false           # 사용자가 저장했는지 여부

      t.timestamps
    end

    # 인덱스: 사용량 통계 쿼리 최적화
    add_index :ai_usage_logs, [:user_id, :created_at]
    add_index :ai_usage_logs, :created_at
    add_index :ai_usage_logs, :status
    add_index :ai_usage_logs, :idea_analysis_id
  end
end
