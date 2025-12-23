class Like < ApplicationRecord
  # 허용된 likeable 타입 (보안: 임의 모델 참조 방지)
  VALID_LIKEABLE_TYPES = %w[Post Comment].freeze

  # Associations
  belongs_to :user
  belongs_to :likeable, polymorphic: true, counter_cache: true
  has_many :notifications, as: :notifiable, dependent: :destroy

  # Validations
  validates :user_id, uniqueness: { scope: [:likeable_type, :likeable_id], message: "already liked this" }
  validates :likeable_type, inclusion: {
    in: VALID_LIKEABLE_TYPES,
    message: "is not a valid likeable type"
  }

  # Callbacks - 알림 생성
  after_create_commit :notify_likeable_owner

  private

  # 좋아요 알림 생성
  def notify_likeable_owner
    recipient = likeable&.user

    # recipient가 없거나 본인인 경우 알림 보내지 않음
    return if recipient.nil? || recipient == user

    # 알림 생성 실패해도 좋아요는 유지 (create! 대신 create 사용)
    Notification.create(
      recipient: recipient,
      actor: user,
      action: "like",
      notifiable: self
    )
  rescue StandardError => e
    # 알림 생성 실패 시 로그만 남기고 진행
    Rails.logger.error("Failed to create notification for like #{id}: #{e.message}")
  end
end
