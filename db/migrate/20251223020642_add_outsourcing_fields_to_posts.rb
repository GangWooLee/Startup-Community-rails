class AddOutsourcingFieldsToPosts < ActiveRecord::Migration[8.1]
  def change
    # 구인/구직 공통
    add_column :posts, :skills, :string              # 필요 기술/보유 기술 (쉼표 구분)
    add_column :posts, :work_type, :string           # 진행 방식: remote, onsite, hybrid

    # 구직 전용
    add_column :posts, :portfolio_url, :string       # 포트폴리오 링크
    add_column :posts, :available_now, :boolean, default: true  # 작업 가능 상태
    add_column :posts, :experience, :text            # 관련 경험/이력
  end
end
