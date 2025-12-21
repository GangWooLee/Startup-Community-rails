class Comment < ApplicationRecord
  # Associations
  belongs_to :post, counter_cache: true
  belongs_to :user
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy

  # Validations
  validates :content, presence: true, length: { minimum: 1, maximum: 1000 }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest, -> { order(created_at: :asc) }
  scope :root_comments, -> { where(parent_id: nil) }

  # 좋아요 관련 헬퍼 메서드
  def liked_by?(user)
    return false unless user
    likes.exists?(user_id: user.id)
  end

  def toggle_like!(user)
    return nil unless user
    existing_like = likes.find_by(user_id: user.id)
    if existing_like
      existing_like.destroy
      false
    else
      likes.create!(user_id: user.id)
      true
    end
  end

  # 대댓글인지 확인
  def reply?
    parent_id.present?
  end

  # 최상위 댓글인지 확인
  def root?
    parent_id.nil?
  end
end
