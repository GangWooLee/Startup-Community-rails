class CreateDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :devices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :platform, null: false  # ios, android
      t.string :token, null: false     # FCM/APNs 토큰
      t.boolean :enabled, default: true, null: false
      t.string :device_name             # 기기 이름 (디버깅용)
      t.string :app_version             # 앱 버전
      t.datetime :last_used_at          # 마지막 사용 시간

      t.timestamps
    end

    # 토큰은 유니크해야 함 (한 기기에 하나의 레코드)
    add_index :devices, :token, unique: true
    # 사용자별 활성 디바이스 조회
    add_index :devices, [:user_id, :enabled]
  end
end
