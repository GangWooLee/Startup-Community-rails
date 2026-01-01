# frozen_string_literal: true

class Inquiry < ApplicationRecord
  # 문의 카테고리
  CATEGORIES = {
    "bug" => "버그 신고",
    "feature" => "기능 제안",
    "improvement" => "개선 요청",
    "other" => "기타 문의"
  }.freeze

  # 처리 상태
  STATUSES = {
    "pending" => "대기 중",
    "in_progress" => "처리 중",
    "resolved" => "답변 완료",
    "closed" => "종료"
  }.freeze

  # Associations
  belongs_to :user
  belongs_to :responded_by, class_name: "User", optional: true

  # Validations
  validates :category, presence: true, inclusion: { in: CATEGORIES.keys, message: "유효하지 않은 카테고리입니다" }
  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true
  validates :status, inclusion: { in: STATUSES.keys }

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :resolved, -> { where(status: "resolved") }
  scope :closed, -> { where(status: "closed") }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :active, -> { where(status: %w[pending in_progress]) }

  # 카테고리 한글 표시
  def category_label
    CATEGORIES[category] || category
  end

  # 처리 상태 한글 표시
  def status_label
    STATUSES[status] || status
  end

  # 상태 확인 헬퍼
  def pending?
    status == "pending"
  end

  def in_progress?
    status == "in_progress"
  end

  def resolved?
    status == "resolved"
  end

  def closed?
    status == "closed"
  end

  # 답변 완료 여부
  def answered?
    admin_response.present?
  end

  # 답변 작성 (관리자용) - 기본적으로 resolved 상태로 변경
  def respond!(admin, response)
    respond_with_status!(admin, response, "resolved")
  end

  # 답변 작성 + 상태 지정 (관리자용)
  def respond_with_status!(admin, response, new_status = "resolved")
    update!(
      admin_response: response,
      responded_by: admin,
      responded_at: Time.current,
      status: new_status
    )
  end

  # 상태 변경 (관리자용)
  def update_status!(new_status)
    update!(status: new_status)
  end
end
