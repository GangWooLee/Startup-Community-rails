class AddRepliesCountToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :replies_count, :integer, default: 0, null: false

    # 기존 데이터의 replies_count 업데이트
    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          UPDATE comments
          SET replies_count = (
            SELECT COUNT(*)
            FROM comments AS replies
            WHERE replies.parent_id = comments.id
          )
        SQL
      end
    end
  end
end
