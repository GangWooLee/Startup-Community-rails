class AddSearchIndexes < ActiveRecord::Migration[8.1]
  def change
    # 사용자 검색 인덱스 (이름, 역할)
    add_index :users, :name, name: "index_users_on_name_for_search"
    add_index :users, :role_title, name: "index_users_on_role_title_for_search"

    # 게시글 검색 인덱스 (제목)
    add_index :posts, :title, name: "index_posts_on_title_for_search"
  end
end
