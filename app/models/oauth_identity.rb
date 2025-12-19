class OauthIdentity < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :uid, presence: true
  validates :provider, uniqueness: { scope: :uid }
  validates :provider, uniqueness: { scope: :user_id }
end
