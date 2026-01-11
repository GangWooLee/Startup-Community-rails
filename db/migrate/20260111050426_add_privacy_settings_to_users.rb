class AddPrivacySettingsToUsers < ActiveRecord::Migration[8.1]
  def change
    # 프로필 섹션별 공개 설정 (false = 비공개, true = 공개)
    # 기본값 false: 익명 모드 시 모든 섹션 비공개
    add_column :users, :privacy_about, :boolean, default: false, null: false
    add_column :users, :privacy_posts, :boolean, default: false, null: false
    add_column :users, :privacy_activity, :boolean, default: false, null: false
    add_column :users, :privacy_experience, :boolean, default: false, null: false
  end
end
