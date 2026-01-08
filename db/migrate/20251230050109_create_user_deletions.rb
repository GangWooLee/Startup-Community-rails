class CreateUserDeletions < ActiveRecord::Migration[8.1]
  def change
    create_table :user_deletions do |t|
      # 사용자 참조
      t.references :user, null: false, foreign_key: true

      # 탈퇴 사유
      t.string :reason_category      # 주요 카테고리
      t.text :reason_detail          # 상세 사유 (기타 선택 시)

      # 상태 관리
      # pending: 탈퇴 대기 중 (30일)
      # completed: 완전 삭제됨
      # restored: 복구됨
      t.string :status, default: "pending", null: false

      # 사용자 데이터 스냅샷 (복구 및 분석용)
      t.json :user_snapshot, null: false

      # 활동 통계 스냅샷 (분석용)
      t.json :activity_stats

      # 시간 정보
      t.datetime :requested_at, null: false      # 탈퇴 요청 시점
      t.datetime :restorable_until, null: false  # 복구 가능 기한 (30일)
      t.datetime :restored_at                     # 복구된 시점
      t.datetime :permanently_deleted_at          # 완전 삭제된 시점

      # IP 정보 (보안 및 분석용)
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :user_deletions, :status
    add_index :user_deletions, :restorable_until
    add_index :user_deletions, [ :user_id, :status ]
  end
end
