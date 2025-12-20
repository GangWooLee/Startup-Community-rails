class RenameOpenChatUrlToLinkedinUrl < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :open_chat_url, :linkedin_url
  end
end
