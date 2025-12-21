class Bookmark < ApplicationRecord
  # 허용된 bookmarkable 타입 (보안: 임의 모델 참조 방지)
  VALID_BOOKMARKABLE_TYPES = %w[Post].freeze

  # Associations
  belongs_to :user
  belongs_to :bookmarkable, polymorphic: true

  # Validations
  validates :user_id, uniqueness: { scope: [:bookmarkable_type, :bookmarkable_id], message: "already bookmarked this" }
  validates :bookmarkable_type, inclusion: {
    in: VALID_BOOKMARKABLE_TYPES,
    message: "is not a valid bookmarkable type"
  }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
end
