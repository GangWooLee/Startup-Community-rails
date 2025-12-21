class RemoveDuplicateIndexes < ActiveRecord::Migration[8.1]
  def change
    # 중복 인덱스 제거:
    # - index_bookmarks_on_bookmarkable은 index_bookmarks_on_bookmarkable_type_and_bookmarkable_id와 동일
    # - index_likes_on_likeable은 index_likes_on_likeable_type_and_likeable_id와 동일

    # bookmarks 테이블 중복 인덱스 제거
    if index_exists?(:bookmarks, [:bookmarkable_type, :bookmarkable_id], name: "index_bookmarks_on_bookmarkable")
      remove_index :bookmarks, name: "index_bookmarks_on_bookmarkable"
    end

    # likes 테이블 중복 인덱스 제거
    if index_exists?(:likes, [:likeable_type, :likeable_id], name: "index_likes_on_likeable")
      remove_index :likes, name: "index_likes_on_likeable"
    end

    # posts 테이블: 복합 인덱스 추가 (status + category + created_at 조합 자주 사용)
    unless index_exists?(:posts, [:status, :category, :created_at])
      add_index :posts, [:status, :category, :created_at], name: "index_posts_on_status_category_created_at"
    end

    # comments 테이블: parent_id + created_at 복합 인덱스 (대댓글 조회 최적화)
    unless index_exists?(:comments, [:parent_id, :created_at])
      add_index :comments, [:parent_id, :created_at], name: "index_comments_on_parent_id_and_created_at"
    end
  end
end
