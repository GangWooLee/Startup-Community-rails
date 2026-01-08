class CreateIdeaAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :idea_analyses do |t|
      t.references :user, null: false, foreign_key: true
      t.text :idea, null: false
      t.json :follow_up_answers
      t.json :analysis_result, null: false
      t.integer :score
      t.boolean :is_real_analysis, default: true
      t.boolean :partial_success, default: false

      t.timestamps
    end

    add_index :idea_analyses, [ :user_id, :created_at ]
  end
end
