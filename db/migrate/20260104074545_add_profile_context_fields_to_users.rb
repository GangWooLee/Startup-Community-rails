class AddProfileContextFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :status_message, :string, limit: 100
    add_column :users, :looking_for, :string, limit: 200
    add_column :users, :location, :string, limit: 50
  end
end
