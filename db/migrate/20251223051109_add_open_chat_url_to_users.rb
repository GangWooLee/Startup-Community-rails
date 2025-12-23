class AddOpenChatUrlToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :open_chat_url, :string
  end
end
