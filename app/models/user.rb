class User < ApplicationRecord
  has_secure_password

  # Associations
  has_many :posts, dependent: :destroy
  has_many :job_posts, dependent: :destroy
  has_many :talent_listings, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :bookmarks, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 1, maximum: 50 }
  validates :password, length: { minimum: 6 }, if: -> { password.present? }
  validates :bio, length: { maximum: 500 }, allow_blank: true
  validates :role_title, length: { maximum: 50 }, allow_blank: true

  # Callbacks
  before_save :downcase_email

  # Scopes
  scope :recent, -> { order(created_at: :desc) }

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
