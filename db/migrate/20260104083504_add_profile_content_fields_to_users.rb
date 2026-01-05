class AddProfileContentFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :toolbox, :text
    add_column :users, :currently_learning, :text
    add_column :users, :work_style, :text
  end
end
