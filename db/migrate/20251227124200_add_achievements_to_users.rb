class AddAchievementsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :achievements, :text
  end
end
