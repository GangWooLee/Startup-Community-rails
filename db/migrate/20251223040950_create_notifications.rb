class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.references :notifiable, polymorphic: true, null: false
      t.datetime :read_at

      t.timestamps
    end

    # 사용자별 최신 알림 조회 최적화
    add_index :notifications, [ :recipient_id, :read_at, :created_at ], name: "index_notifications_on_recipient_and_status"
  end
end
