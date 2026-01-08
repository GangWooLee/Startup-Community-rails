class CreateJobPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :job_posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description, null: false
      t.integer :category, default: 0, null: false
      t.integer :project_type, default: 0, null: false
      t.string :budget
      t.integer :status, default: 0, null: false
      t.integer :views_count, default: 0

      t.timestamps
    end

    add_index :job_posts, [ :user_id, :created_at ]
    add_index :job_posts, :category
    add_index :job_posts, :status
    add_index :job_posts, :created_at
  end
end
