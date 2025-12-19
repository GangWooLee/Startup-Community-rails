class AddAvailabilityStatusesAndCustomStatusToUsers < ActiveRecord::Migration[8.1]
  def change
    # 기존 availability_status가 있으면 삭제
    if column_exists?(:users, :availability_status)
      remove_column :users, :availability_status
    end

    # 새 컬럼 추가 (없을 때만)
    unless column_exists?(:users, :availability_statuses)
      add_column :users, :availability_statuses, :json, default: []
    end

    unless column_exists?(:users, :custom_status)
      add_column :users, :custom_status, :string
    end
  end
end
