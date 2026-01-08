class AddProfileOnboardingToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :nickname, :string
    add_column :users, :avatar_type, :integer, default: 0
    add_column :users, :profile_completed, :boolean, default: false
    add_column :users, :is_anonymous, :boolean, default: true

    # 기존 사용자들은 실명으로 활동 중이므로 완료 처리
    reversible do |dir|
      dir.up do
        User.update_all(
          profile_completed: true,
          is_anonymous: false
        )
      end
    end

    add_index :users, :nickname, unique: true
  end
end
