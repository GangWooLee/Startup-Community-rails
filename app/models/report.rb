# frozen_string_literal: true

class Report < ApplicationRecord
  # 허용된 reportable 타입 (보안: 임의 모델 참조 방지)
  VALID_REPORTABLE_TYPES = %w[Post User ChatRoom].freeze

  # 신고 사유
  REASONS = {
    "spam" => "스팸/광고",
    "inappropriate" => "부적절한 콘텐츠",
    "harassment" => "괴롭힘/욕설",
    "scam" => "사기/허위정보",
    "other" => "기타"
  }.freeze

  # 처리 상태
  STATUSES = {
    "pending" => "대기 중",
    "reviewed" => "검토됨",
    "resolved" => "처리완료",
    "dismissed" => "기각"
  }.freeze

  # Associations
  belongs_to :reporter, class_name: "User"
  belongs_to :reportable, polymorphic: true
  belongs_to :resolved_by, class_name: "User", optional: true

  # Validations
  validates :reason, presence: true, inclusion: { in: REASONS.keys, message: "유효하지 않은 신고 사유입니다" }
  validates :status, inclusion: { in: STATUSES.keys }
  validates :reporter_id, uniqueness: {
    scope: [ :reportable_type, :reportable_id ],
    message: "이미 신고한 항목입니다"
  }
  validates :reportable_type, inclusion: {
    in: VALID_REPORTABLE_TYPES,
    message: "유효하지 않은 신고 대상입니다"
  }

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :reviewed, -> { where(status: "reviewed") }
  scope :resolved, -> { where(status: "resolved") }
  scope :dismissed, -> { where(status: "dismissed") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(reportable_type: type) if type.present? }

  # 신고 사유 한글 표시
  def reason_label
    REASONS[reason] || reason
  end

  # 처리 상태 한글 표시
  def status_label
    STATUSES[status] || status
  end

  # 신고 대상 타입 한글 표시
  def reportable_type_label
    case reportable_type
    when "Post" then "게시글"
    when "User" then "사용자"
    when "ChatRoom" then "채팅방"
    else reportable_type
    end
  end

  # 상태 확인 헬퍼
  def pending?
    status == "pending"
  end

  def reviewed?
    status == "reviewed"
  end

  # 처리 완료 여부 (resolved 또는 dismissed)
  def resolved?
    status.in?(%w[resolved dismissed])
  end

  # 상태 변경 (관리자용)
  def resolve!(admin, new_status, note = nil)
    update!(
      status: new_status,
      resolved_by: admin,
      resolved_at: Time.current,
      admin_note: note
    )
  end
end
