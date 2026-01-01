class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :reportable, polymorphic: true, null: false
      t.string :reason, null: false
      t.text :description
      t.string :status, null: false, default: "pending"
      t.text :admin_note
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :reports, [:reporter_id, :reportable_type, :reportable_id],
              unique: true, name: "index_reports_on_reporter_and_reportable"
  end
end
