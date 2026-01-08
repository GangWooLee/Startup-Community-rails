class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false
      t.integer :status, default: 0, null: false
      t.integer :views_count, default: 0
      t.integer :likes_count, default: 0
      t.integer :comments_count, default: 0

      t.timestamps
    end

    add_index :posts, [ :user_id, :created_at ]
    add_index :posts, :status
    add_index :posts, :created_at
  end
end
