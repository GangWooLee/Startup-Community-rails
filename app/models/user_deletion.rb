# 회원 탈퇴 기록 모델
# - 암호화된 개인정보 보관 (법적 보관 의무)
# - 활동 통계 저장 (분석용)
# - 5년 후 자동 파기
class UserDeletion < ApplicationRecord
  belongs_to :user

  # ===== Rails 7 Active Record Encryption =====
  # 암호화된 개인정보 (복호화 가능 - 관리자 열람용)
  encrypts :email_original
  encrypts :name_original
  encrypts :phone_original
  encrypts :snapshot_data

  # 재가입 방지용 해시 (deterministic = 같은 입력 → 같은 출력, 검색 가능)
  encrypts :email_hash, deterministic: true

  # ===== 상수 =====
  STATUSES = {
    pending: "pending",       # 레거시 (사용 안 함)
    completed: "completed"    # 즉시 익명화 완료
  }.freeze

  REASON_CATEGORIES = {
    "not_using" => "서비스를 더 이상 사용하지 않음",
    "found_alternative" => "다른 서비스로 이동",
    "privacy_concern" => "개인정보 보호 우려",
    "too_many_notifications" => "알림이 너무 많음",
    "not_useful" => "유용한 정보가 없음",
    "technical_issues" => "기술적 문제 (버그 등)",
    "other" => "기타"
  }.freeze

  # 법적 보관 기간 (전자상거래법)
  RETENTION_PERIOD = 5.years

  # ===== Validations =====
  validates :status, presence: true, inclusion: { in: STATUSES.values }
  validates :reason_category, inclusion: { in: REASON_CATEGORIES.keys }, allow_blank: true
  validates :requested_at, presence: true

  # ===== Callbacks =====
  before_create :set_destroy_scheduled_at

  # ===== Scopes =====
  scope :pending, -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }
  scope :recent, -> { order(created_at: :desc) }
  scope :expiring_soon, -> { where("destroy_scheduled_at <= ?", 30.days.from_now) }
  scope :expired, -> { where("destroy_scheduled_at <= ?", Time.current) }

  # ===== Instance Methods =====

  # 탈퇴 사유 라벨
  def reason_label
    REASON_CATEGORIES[reason_category] || reason_category || "미선택"
  end

  # 파기 예정일까지 남은 일수
  def days_until_destruction
    return 0 unless destroy_scheduled_at
    days = ((destroy_scheduled_at - Time.current) / 1.day).ceil
    [days, 0].max
  end

  # 스냅샷 데이터 파싱 (암호화된 JSON)
  def parsed_snapshot
    return {} if snapshot_data.blank?
    JSON.parse(snapshot_data)
  rescue JSON::ParserError
    {}
  end

  # 활동 통계 (기존 컬럼 호환)
  def activity_stats_hash
    return {} if activity_stats.blank?
    activity_stats.is_a?(Hash) ? activity_stats : JSON.parse(activity_stats.to_s)
  rescue JSON::ParserError
    {}
  end

  # 관리자 열람 기록
  def record_admin_view!(admin:, reason:, ip_address: nil, user_agent: nil)
    AdminViewLog.create!(
      admin: admin,
      target: self,
      action: "reveal_personal_info",
      reason: reason,
      ip_address: ip_address,
      user_agent: user_agent
    )

    increment!(:admin_view_count)
    update!(last_viewed_at: Time.current, last_viewed_by: admin.id)
  end

  private

  def set_destroy_scheduled_at
    self.destroy_scheduled_at ||= RETENTION_PERIOD.from_now
  end
end
