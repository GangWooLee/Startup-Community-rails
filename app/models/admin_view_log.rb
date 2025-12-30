# 관리자 개인정보 열람 로그
# - 감사 추적(Audit Trail)용
# - 법적 의무 준수 증빙
class AdminViewLog < ApplicationRecord
  belongs_to :admin, class_name: "User"
  belongs_to :target, polymorphic: true

  # Validations
  validates :action, presence: true
  validates :reason, presence: true, length: { minimum: 5, message: "는 최소 5자 이상 입력해주세요" }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_admin, ->(admin_id) { where(admin_id: admin_id) }
  scope :for_target, ->(target) { where(target: target) }

  # 액션 타입
  ACTIONS = {
    reveal_personal_info: "reveal_personal_info",  # 개인정보 열람
    view_snapshot: "view_snapshot",                # 스냅샷 열람
    export_data: "export_data"                     # 데이터 내보내기
  }.freeze
end
