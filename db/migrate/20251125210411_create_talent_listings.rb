class CreateTalentListings < ActiveRecord::Migration[8.1]
  def change
    create_table :talent_listings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description, null: false
      t.integer :category, default: 0, null: false
      t.integer :project_type, default: 0, null: false
      t.string :rate
      t.integer :status, default: 0, null: false
      t.integer :views_count, default: 0

      t.timestamps
    end

    add_index :talent_listings, [ :user_id, :created_at ]
    add_index :talent_listings, :category
    add_index :talent_listings, :status
    add_index :talent_listings, :created_at
  end
end
