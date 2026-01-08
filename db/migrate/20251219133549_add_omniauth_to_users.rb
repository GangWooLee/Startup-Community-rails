class AddOmniauthToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string

    # Add index for OAuth lookup
    add_index :users, [ :provider, :uid ], unique: true
  end
end
