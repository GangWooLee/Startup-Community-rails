# frozen_string_literal: true

# 약관 동의 관련 기능
# 사용: include Termable
#
# 제공 메서드:
# - terms_accepted?: 이용약관 동의 여부
# - privacy_accepted?: 개인정보처리방침 동의 여부
# - guidelines_accepted?: 커뮤니티 가이드라인 동의 여부
# - all_terms_accepted?: 모든 약관 동의 여부
# - accept_terms!(version:): 약관 동의 처리 (OAuth 사용자용)
# - set_terms_accepted!: 약관 동의 시간 일괄 설정 (회원가입 시)
module Termable
  extend ActiveSupport::Concern

  included do
    CURRENT_TERMS_VERSION = "1.0".freeze
  end

  # 이용약관 동의 여부 확인
  def terms_accepted?
    terms_accepted_at.present?
  end

  # 개인정보처리방침 동의 여부 확인
  def privacy_accepted?
    privacy_accepted_at.present?
  end

  # 커뮤니티 가이드라인 동의 여부 확인
  def guidelines_accepted?
    guidelines_accepted_at.present?
  end

  # 모든 약관 동의 여부 확인
  def all_terms_accepted?
    terms_accepted_at.present? &&
    privacy_accepted_at.present? &&
    guidelines_accepted_at.present?
  end

  # 약관 동의 처리 (OAuth 사용자용)
  def accept_terms!(version: CURRENT_TERMS_VERSION)
    now = Time.current
    update!(
      terms_accepted_at: now,
      privacy_accepted_at: now,
      guidelines_accepted_at: now,
      terms_version: version
    )
  end

  # 약관 동의 시간 일괄 설정 (회원가입 시 사용)
  def set_terms_accepted!
    now = Time.current
    self.terms_accepted_at = now
    self.privacy_accepted_at = now
    self.guidelines_accepted_at = now
    self.terms_version = CURRENT_TERMS_VERSION
  end
end
