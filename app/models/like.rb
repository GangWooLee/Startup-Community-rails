class Like < ApplicationRecord
  # 허용된 likeable 타입 (보안: 임의 모델 참조 방지)
  VALID_LIKEABLE_TYPES = %w[Post Comment].freeze

  # Associations
  belongs_to :user
  belongs_to :likeable, polymorphic: true, counter_cache: true

  # Validations
  validates :user_id, uniqueness: { scope: [:likeable_type, :likeable_id], message: "already liked this" }
  validates :likeable_type, inclusion: {
    in: VALID_LIKEABLE_TYPES,
    message: "is not a valid likeable type"
  }
end
