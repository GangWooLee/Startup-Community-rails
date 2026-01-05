class AddNotificationsEnabledToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :notifications_enabled, :boolean, default: true, null: false
  end
end
