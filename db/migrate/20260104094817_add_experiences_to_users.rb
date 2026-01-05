class AddExperiencesToUsers < ActiveRecord::Migration[8.1]
  def change
    # Experience Timeline JSON 배열
    # 구조: [{ type: "work|education|project", title: "직책/학위",
    #          organization: "회사/학교", period: "2023.03 - 현재",
    #          description: "설명", is_current: true/false }]
    add_column :users, :experiences, :json, default: []
  end
end
