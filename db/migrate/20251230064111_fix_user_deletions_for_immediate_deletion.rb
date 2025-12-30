# 즉시 익명화 방식으로 전환 - 레거시 컬럼 정리
class FixUserDeletionsForImmediateDeletion < ActiveRecord::Migration[8.1]
  def change
    # restorable_until NULL 허용 (즉시 삭제에서는 불필요)
    change_column_null :user_deletions, :restorable_until, true

    # 레거시 컬럼 정리 (복구 기능 제거됨)
    remove_column :user_deletions, :restored_at, :datetime
  end
end
