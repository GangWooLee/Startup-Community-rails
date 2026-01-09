# frozen_string_literal: true

# 회원 탈퇴 관련 기능
# 사용: include Deletable
#
# 제공 메서드:
# - deleted?: 탈퇴한 사용자인지 확인
# - active?: 활성 사용자인지 확인
# - last_deletion: 가장 최근 탈퇴 기록 (관리자용)
#
# 제공 Scopes:
# - active: 활성 사용자만
# - deleted: 탈퇴한 사용자만
module Deletable
  extend ActiveSupport::Concern

  included do
    # 회원 탈퇴 기록
    has_many :user_deletions, dependent: :destroy

    # Scopes
    scope :active, -> { where(deleted_at: nil) }
    scope :deleted, -> { where.not(deleted_at: nil) }

    # 재가입 방지: 탈퇴한 이메일로는 재가입 불가
    validate :check_blacklisted_email, on: :create
  end

  # 탈퇴한 사용자인지 확인
  def deleted?
    deleted_at.present?
  end

  # 활성 사용자인지 확인
  def active?
    deleted_at.nil?
  end

  # 가장 최근 탈퇴 기록 가져오기 (관리자용)
  def last_deletion
    user_deletions.order(created_at: :desc).first
  end

  private

  # 재가입 방지: 탈퇴한 이메일 해시와 비교
  def check_blacklisted_email
    return if email.blank?

    email_hash = Digest::SHA256.hexdigest(email.to_s.downcase.strip)
    if UserDeletion.exists?(email_hash: email_hash)
      errors.add(:email, "이전에 탈퇴한 이메일입니다. 다른 이메일로 가입하거나 고객센터에 문의해주세요.")
    end
  end
end
