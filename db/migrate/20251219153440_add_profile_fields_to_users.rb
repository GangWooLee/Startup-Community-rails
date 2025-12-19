class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    # 소속 (예: "21학번/CS", "스타트업 재직중", "프리랜서")
    add_column :users, :affiliation, :string

    # 활동 상태 (0: 기본, 1: 외주가능, 2: 팀구하는중, 3: 재직중)
    add_column :users, :availability_status, :integer, default: 0

    # 연락처
    add_column :users, :open_chat_url, :string
    add_column :users, :portfolio_url, :string
    add_column :users, :github_url, :string

    # 기술 스택 (쉼표로 구분된 문자열)
    add_column :users, :skills, :string
  end
end
