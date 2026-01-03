class AddAiAnalysisLimitToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :ai_analysis_limit, :integer
  end
end
