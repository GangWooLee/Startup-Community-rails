class AddIsSavedToIdeaAnalyses < ActiveRecord::Migration[8.1]
  def change
    add_column :idea_analyses, :is_saved, :boolean, default: false, null: false
    add_index :idea_analyses, [ :is_saved, :updated_at ], name: "idx_idea_analyses_unsaved_cleanup"
  end
end
