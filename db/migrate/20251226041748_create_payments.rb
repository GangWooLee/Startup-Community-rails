# 결제 테이블 - 토스페이먼츠 결제 상세 정보
# Order에 대한 실제 결제 트랜잭션 기록
class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      # 관계
      t.references :order, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      # 토스페이먼츠 필드
      t.string :payment_key                   # 토스페이먼츠 고유 결제 키
      t.string :toss_order_id, null: false    # 토스에 전송하는 주문 ID (PAY-xxx 형식)
      t.integer :amount, null: false          # 결제 금액 (원)

      # 결제 수단 정보
      t.string :method                        # CARD, VIRTUAL_ACCOUNT, TRANSFER, MOBILE 등
      t.string :method_detail                 # 카드사명, 은행명 등
      t.string :card_company                  # 카드 결제 시 카드사
      t.string :card_number                   # 마스킹된 카드 번호
      t.string :card_type                     # CREDIT, DEBIT, GIFT 등
      t.string :receipt_url                   # 영수증 URL

      # 상태 관리
      t.integer :status, default: 0, null: false  # pending, ready, done, cancelled, failed
      t.string :failure_code                  # 실패 시 에러 코드
      t.string :failure_message               # 실패 시 에러 메시지

      # 원본 응답 저장 (디버깅용)
      t.json :raw_response

      # 타임스탬프
      t.datetime :approved_at                 # 승인 시각
      t.datetime :cancelled_at                # 취소 시각

      t.timestamps
    end

    # 인덱스
    add_index :payments, :payment_key, unique: true
    add_index :payments, :toss_order_id, unique: true
    add_index :payments, [:user_id, :created_at]
    add_index :payments, :status
  end
end
