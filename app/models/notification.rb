class Notification < ApplicationRecord
  # 알림을 받는 사용자
  belongs_to :recipient, class_name: "User"
  # 알림을 발생시킨 사용자
  belongs_to :actor, class_name: "User"
  # 알림의 대상 객체 (Post, Comment, Like 등)
  # optional: true - notifiable이 삭제될 수 있음 (dependent: :destroy 대신 사용자가 직접 삭제 시)
  belongs_to :notifiable, polymorphic: true, optional: true

  # 액션 타입
  ACTIONS = %w[comment like reply follow apply].freeze

  # Validations
  validates :action, presence: true, inclusion: { in: ACTIONS }

  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_recipient, ->(user) { where(recipient: user) }

  # 읽음 처리
  def mark_as_read!
    update!(read_at: Time.current) if read_at.nil?
  end

  def read?
    read_at.present?
  end

  def unread?
    read_at.nil?
  end

  # 알림 메시지 생성
  def message
    case action
    when "comment"
      "#{actor.name}님이 회원님의 글에 댓글을 남겼습니다."
    when "like"
      "#{actor.name}님이 회원님의 글을 좋아합니다."
    when "reply"
      "#{actor.name}님이 회원님의 댓글에 답글을 남겼습니다."
    when "follow"
      "#{actor.name}님이 회원님을 팔로우합니다."
    when "apply"
      "#{actor.name}님이 회원님의 공고에 지원했습니다."
    else
      "새로운 알림이 있습니다."
    end
  end

  # 알림 클릭 시 이동할 경로
  # 항상 유효한 경로를 반환하도록 보장
  def target_path
    path = case notifiable_type
    when "Post"
      "/posts/#{notifiable_id}"
    when "Comment"
      comment = notifiable
      if comment&.post_id
        "/posts/#{comment.post_id}#comment-#{notifiable_id}"
      end
    when "Like"
      like = notifiable
      if like&.likeable_type == "Post" && like.likeable_id
        "/posts/#{like.likeable_id}"
      elsif like&.likeable_type == "Comment" && like.likeable&.post_id
        "/posts/#{like.likeable.post_id}#comment-#{like.likeable_id}"
      end
    when "JobPost"
      "/job_posts/#{notifiable_id}"
    when "TalentListing"
      "/talent_listings/#{notifiable_id}"
    end

    # nil이면 기본 경로 반환
    path || "/"
  end

  # 클래스 메서드: 일괄 읽음 처리
  def self.mark_all_as_read!
    unread.update_all(read_at: Time.current)
  end
end
