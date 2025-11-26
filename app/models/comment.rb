class Comment < ApplicationRecord
  # Associations
  belongs_to :post, counter_cache: true
  belongs_to :user

  # Validations
  validates :content, presence: true, length: { minimum: 1, maximum: 1000 }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
end
