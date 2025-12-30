# 관리자 개인정보 열람 로그 (감사 추적용)
class CreateAdminViewLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_view_logs do |t|
      t.references :admin, null: false, foreign_key: { to_table: :users }
      t.references :target, polymorphic: true, null: false  # UserDeletion 등
      t.string :action, null: false          # reveal_personal_info, view_snapshot 등
      t.text :reason, null: false            # 열람 사유 (필수)
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :admin_view_logs, [:target_type, :target_id]
    add_index :admin_view_logs, :created_at
  end
end
