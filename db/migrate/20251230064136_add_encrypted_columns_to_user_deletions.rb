# 암호화된 개인정보 보관 + 관리자 열람 로깅 컬럼 추가
class AddEncryptedColumnsToUserDeletions < ActiveRecord::Migration[8.1]
  def change
    # 암호화된 개인정보 컬럼 (Rails 7 Active Record Encryption 사용)
    add_column :user_deletions, :email_original, :string      # 암호화됨
    add_column :user_deletions, :name_original, :string       # 암호화됨
    add_column :user_deletions, :phone_original, :string      # 암호화됨
    add_column :user_deletions, :snapshot_data, :text         # 암호화된 JSON

    # 재가입 방지용 해시 (단방향 - 복호화 불가)
    add_column :user_deletions, :email_hash, :string
    add_index :user_deletions, :email_hash

    # 자동 파기 예정일 (법적 보관 기간 후)
    add_column :user_deletions, :destroy_scheduled_at, :datetime
    add_index :user_deletions, :destroy_scheduled_at

    # 관리자 열람 추적
    add_column :user_deletions, :admin_view_count, :integer, default: 0
    add_column :user_deletions, :last_viewed_at, :datetime
    add_column :user_deletions, :last_viewed_by, :integer  # admin user_id
  end
end
