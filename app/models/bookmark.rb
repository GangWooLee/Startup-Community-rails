class Bookmark < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :bookmarkable, polymorphic: true

  # Validations
  validates :user_id, uniqueness: { scope: [:bookmarkable_type, :bookmarkable_id], message: "already bookmarked this" }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
end
