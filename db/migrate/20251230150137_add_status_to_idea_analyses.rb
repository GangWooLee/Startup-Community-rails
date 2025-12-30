class AddStatusToIdeaAnalyses < ActiveRecord::Migration[8.1]
  def change
    add_column :idea_analyses, :status, :string, default: "completed", null: false
    add_index :idea_analyses, :status
  end
end
