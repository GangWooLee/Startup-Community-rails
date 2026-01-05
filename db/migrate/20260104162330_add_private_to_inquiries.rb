class AddPrivateToInquiries < ActiveRecord::Migration[8.1]
  def change
    add_column :inquiries, :is_private, :boolean, default: false, null: false
  end
end
