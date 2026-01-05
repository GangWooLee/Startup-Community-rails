class AddTermsAgreementToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :terms_accepted_at, :datetime
    add_column :users, :privacy_accepted_at, :datetime
    add_column :users, :guidelines_accepted_at, :datetime
    add_column :users, :terms_version, :string, default: "1.0"

    # 기존 사용자는 가입 시점을 동의 시점으로 설정 (백필)
    # 법적 근거: 기존 가입자는 가입 시 묵시적 동의한 것으로 간주
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE users
          SET terms_accepted_at = created_at,
              privacy_accepted_at = created_at,
              guidelines_accepted_at = created_at,
              terms_version = '1.0'
          WHERE deleted_at IS NULL
        SQL
      end
    end
  end
end
