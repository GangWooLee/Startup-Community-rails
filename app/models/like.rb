class Like < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :likeable, polymorphic: true, counter_cache: true

  # Validations
  validates :user_id, uniqueness: { scope: [:likeable_type, :likeable_id], message: "already liked this" }
end
