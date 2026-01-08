class CreateOauthIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_identities do |t|
      t.string :provider, null: false
      t.string :uid, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # provider + uid 조합은 고유해야 함
    add_index :oauth_identities, [ :provider, :uid ], unique: true
    # 한 사용자가 같은 provider를 중복 연결할 수 없음
    add_index :oauth_identities, [ :user_id, :provider ], unique: true
  end
end
