class AddParentAndLikesToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :parent_id, :integer
    add_column :comments, :likes_count, :integer, default: 0
    add_index :comments, :parent_id
    add_foreign_key :comments, :comments, column: :parent_id, on_delete: :cascade
  end
end
