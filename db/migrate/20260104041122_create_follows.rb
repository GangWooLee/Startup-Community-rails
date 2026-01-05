class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows do |t|
      t.references :follower, null: false, foreign_key: { to_table: :users }
      t.references :followed, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    # Unique constraint: A user can only follow another user once
    add_index :follows, [:follower_id, :followed_id], unique: true

    # For efficient follower/following list queries
    add_index :follows, [:followed_id, :created_at]
  end
end
