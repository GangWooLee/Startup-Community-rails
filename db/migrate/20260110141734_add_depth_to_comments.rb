# frozen_string_literal: true

# 댓글 깊이(depth) 컬럼 추가
#
# 목적: N+1 쿼리 방지 - 부모 순회 대신 컬럼에서 직접 조회
# 규칙:
#   - depth 0: 최상위 댓글 (parent_id = NULL)
#   - depth 1: 대댓글 (MAX_DEPTH)
#   - depth N: N번째 깊이의 댓글
class AddDepthToComments < ActiveRecord::Migration[8.1]
  def up
    add_column :comments, :depth, :integer, default: 0, null: false

    # 기존 데이터 업데이트: parent_id가 있으면 depth = 1 (현재 MAX_DEPTH=1이므로)
    # 더 깊은 깊이가 필요하면 재귀 업데이트 필요
    execute <<-SQL.squish
      UPDATE comments
      SET depth = 1
      WHERE parent_id IS NOT NULL
    SQL
  end

  def down
    remove_column :comments, :depth
  end
end
