class Comment < ApplicationRecord
  # Concerns
  include Likeable

  # 대댓글 최대 깊이 (1 = 대댓글만 허용, 대대댓글 불가)
  MAX_DEPTH = 1

  # Associations
  belongs_to :post, counter_cache: true
  belongs_to :user
  belongs_to :parent, class_name: "Comment", optional: true, counter_cache: :replies_count
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy

  # Validations
  validates :content, presence: true, length: { minimum: 1, maximum: 1000 }
  validate :parent_belongs_to_same_post
  validate :parent_depth_limit
  validate :cannot_be_own_parent

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest, -> { order(created_at: :asc) }
  scope :root_comments, -> { where(parent_id: nil) }

  # Callbacks - 알림 생성
  after_create_commit :notify_recipient

  # 대댓글인지 확인
  def reply?
    parent_id.present?
  end

  # 최상위 댓글인지 확인
  def root?
    parent_id.nil?
  end

  # 현재 댓글의 깊이 계산
  def depth
    return 0 unless parent_id
    count = 0
    current = parent
    while current
      count += 1
      current = current.parent
    end
    count
  end

  private

  # 부모 댓글이 같은 게시글에 속하는지 검증
  def parent_belongs_to_same_post
    return unless parent_id.present? && parent.present?
    if parent.post_id != post_id
      errors.add(:parent, "must belong to the same post")
    end
  end

  # 대댓글 깊이 제한 검증
  def parent_depth_limit
    return unless parent_id.present? && parent.present?
    if parent.depth >= MAX_DEPTH
      errors.add(:parent, "reply depth limit exceeded")
    end
  end

  # 자기 자신을 부모로 설정할 수 없음
  def cannot_be_own_parent
    if parent_id.present? && parent_id == id
      errors.add(:parent, "cannot be self")
    end
  end

  # 댓글/대댓글 알림 생성
  def notify_recipient
    if reply?
      # 대댓글: 부모 댓글 작성자에게 알림
      recipient = parent&.user
      action = "reply"
    else
      # 댓글: 게시글 작성자에게 알림
      recipient = post&.user
      action = "comment"
    end

    # recipient가 없거나 본인인 경우 알림 보내지 않음
    return if recipient.nil? || recipient == user

    # 알림 생성 실패해도 댓글 작성은 유지 (create! 대신 create 사용)
    Notification.create(
      recipient: recipient,
      actor: user,
      action: action,
      notifiable: self
    )
  rescue StandardError => e
    # 알림 생성 실패 시 로그만 남기고 진행
    Rails.logger.error("Failed to create notification for comment #{id}: #{e.message}")
  end
end
