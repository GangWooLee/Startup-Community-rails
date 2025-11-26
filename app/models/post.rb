class Post < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy
  has_many :bookmarks, as: :bookmarkable, dependent: :destroy

  # Enums
  enum :status, { draft: 0, published: 1, archived: 2 }, default: :draft

  # Validations
  validates :title, presence: true, length: { minimum: 1, maximum: 255 }
  validates :content, presence: true, length: { minimum: 1 }
  validates :status, presence: true

  # Scopes
  scope :published, -> { where(status: :published) }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { order(likes_count: :desc, views_count: :desc) }

  # Instance methods
  def increment_views!
    increment!(:views_count)
  end
end
