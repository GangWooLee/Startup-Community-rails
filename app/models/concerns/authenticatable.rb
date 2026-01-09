# frozen_string_literal: true

# Remember Me 인증 기능
# 사용: include Authenticatable
#
# 제공 메서드:
# - remember: 영구 세션용 토큰 생성 및 저장
# - forget: 토큰 삭제 (로그아웃 시)
# - authenticated?(token): 쿠키 토큰 유효성 확인
module Authenticatable
  extend ActiveSupport::Concern

  included do
    # Remember Me 토큰 (DB에 저장되지 않는 가상 속성)
    attr_accessor :remember_token
  end

  # Remember Me: 영구 세션용 토큰 생성 및 저장
  def remember
    self.remember_token = SecureRandom.urlsafe_base64
    update_column(:remember_digest, BCrypt::Password.create(remember_token))
  end

  # Remember Me: 토큰 삭제 (로그아웃 시)
  def forget
    update_column(:remember_digest, nil)
  end

  # Remember Me: 쿠키의 토큰이 유효한지 확인
  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end
end
