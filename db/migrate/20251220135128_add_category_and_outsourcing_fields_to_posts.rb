class AddCategoryAndOutsourcingFieldsToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :category, :integer, default: 0, null: false
    add_column :posts, :service_type, :string
    add_column :posts, :price, :integer
    add_column :posts, :work_period, :string
    add_column :posts, :price_negotiable, :boolean, default: false

    add_index :posts, :category
  end
end
