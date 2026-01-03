class AddAiBonusCreditsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :ai_bonus_credits, :integer, default: 0, null: false
  end
end
