class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :chat_room, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :content, null: false

      t.timestamps
    end

    add_index :messages, [ :chat_room_id, :created_at ]
    # sender_id index is already created by t.references
  end
end
