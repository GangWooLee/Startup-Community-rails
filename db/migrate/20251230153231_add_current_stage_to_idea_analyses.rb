class AddCurrentStageToIdeaAnalyses < ActiveRecord::Migration[8.1]
  def change
    add_column :idea_analyses, :current_stage, :integer, default: 0
  end
end
