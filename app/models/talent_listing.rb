class TalentListing < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :bookmarks, as: :bookmarkable, dependent: :destroy

  # Enums
  enum :category, { development: 0, design: 1, pm: 2, marketing: 3 }, default: :development
  enum :project_type, { short_term: 0, long_term: 1, one_time: 2 }, default: :short_term
  enum :status, { available: 0, unavailable: 1 }, default: :available

  # Validations
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  validates :description, presence: true, length: { minimum: 1 }
  validates :category, presence: true
  validates :project_type, presence: true
  validates :status, presence: true

  # Scopes
  scope :available, -> { where(status: :available) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }

  # Instance methods
  def increment_views!
    increment!(:views_count)
  end

  def category_i18n
    {
      development: '개발',
      design: '디자인',
      pm: 'PM/기획',
      marketing: '마케팅'
    }[category.to_sym]
  end

  def project_type_i18n
    {
      short_term: '단기',
      long_term: '장기',
      one_time: '단발'
    }[project_type.to_sym]
  end

  def status_i18n
    {
      available: '구직중',
      unavailable: '구직완료'
    }[status.to_sym]
  end
end
