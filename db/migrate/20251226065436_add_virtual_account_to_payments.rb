# 가상계좌 결제 지원을 위한 필드 추가
# 가상계좌 발급 시 은행 정보, 계좌번호, 입금 기한 저장
class AddVirtualAccountToPayments < ActiveRecord::Migration[8.1]
  def change
    # 가상계좌 정보
    add_column :payments, :bank_code, :string        # 은행 코드 (예: 88 = 신한은행)
    add_column :payments, :bank_name, :string        # 은행명 (예: 신한은행)
    add_column :payments, :account_number, :string   # 가상계좌 번호
    add_column :payments, :account_holder, :string   # 예금주명
    add_column :payments, :due_date, :datetime       # 입금 기한

    # 가상계좌 상태 조회용 인덱스 (입금 대기 중인 가상계좌)
    add_index :payments, [ :status, :due_date ], name: "index_payments_on_virtual_account_pending"
  end
end
