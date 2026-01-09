class CreatePostViews < ActiveRecord::Migration[8.1]
  def change
    create_table :post_views do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end

    # 중복 방지: User + Post 조합은 고유해야 함
    add_index :post_views, [ :user_id, :post_id ], unique: true
  end
end
