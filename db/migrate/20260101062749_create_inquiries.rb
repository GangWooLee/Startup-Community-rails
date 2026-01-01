class CreateInquiries < ActiveRecord::Migration[8.1]
  def change
    create_table :inquiries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :category, null: false
      t.string :title, null: false
      t.text :content, null: false
      t.string :status, null: false, default: "pending"
      t.text :admin_response
      t.references :responded_by, foreign_key: { to_table: :users }
      t.datetime :responded_at

      t.timestamps
    end

    add_index :inquiries, :status
    add_index :inquiries, :category
  end
end
