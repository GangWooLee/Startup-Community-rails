# 주문 테이블 - 비즈니스 거래 정보
# 구매자가 외주 글(Post)에 대해 결제할 때 생성됨
class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      # 주문 번호 (고유 식별자)
      t.string :order_number, null: false

      # 관계
      t.references :user, null: false, foreign_key: true      # 구매자
      t.references :post, null: false, foreign_key: true      # 외주 글
      t.references :seller, null: false, foreign_key: { to_table: :users }  # 판매자 (post.user)

      # 주문 정보
      t.string :title, null: false                            # 주문 제목 (표시용)
      t.integer :amount, null: false                          # 결제 금액 (원)
      t.text :description                                     # 추가 설명

      # 주문 타입 (향후 확장용)
      t.integer :order_type, default: 0, null: false          # outsourcing, premium, promotion

      # 상태 관리
      t.integer :status, default: 0, null: false              # pending, paid, cancelled, refunded

      # 타임스탬프
      t.datetime :paid_at                                     # 결제 완료 시각
      t.datetime :cancelled_at                                # 취소 시각
      t.datetime :refunded_at                                 # 환불 시각

      t.timestamps
    end

    # 인덱스
    add_index :orders, :order_number, unique: true
    add_index :orders, [:user_id, :created_at]
    add_index :orders, [:seller_id, :created_at]
    add_index :orders, [:post_id, :status]
    add_index :orders, :status
    add_index :orders, :order_type
  end
end
