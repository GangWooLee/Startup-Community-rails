# frozen_string_literal: true

# == Schema Information
#
# Table name: follows
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  followed_id :integer          not null
#  follower_id :integer          not null
#
# Indexes
#
#  index_follows_on_followed_id_and_created_at  (followed_id,created_at)
#  index_follows_on_follower_id                 (follower_id)
#  index_follows_on_follower_id_and_followed_id (follower_id,followed_id) UNIQUE
#
# Foreign Keys
#
#  followed_id  (followed_id => users.id)
#  follower_id  (follower_id => users.id)
#
class Follow < ApplicationRecord
  # Associations
  belongs_to :follower, class_name: "User", counter_cache: :following_count
  belongs_to :followed, class_name: "User", counter_cache: :followers_count

  # Validations
  validates :follower_id, uniqueness: { scope: :followed_id, message: "이미 팔로우 중입니다" }
  validate :cannot_follow_self

  # Callbacks
  after_create_commit :notify_followed_user

  private

  def cannot_follow_self
    errors.add(:followed_id, "자신을 팔로우할 수 없습니다") if follower_id == followed_id
  end

  def notify_followed_user
    Notification.create!(
      recipient: followed,
      actor: follower,
      action: "follow",
      notifiable: self
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to create follow notification: #{e.message}")
  end
end
