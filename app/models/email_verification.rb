# 회원가입 이메일 인증 코드 관리
# - 6자리 영문+숫자 코드 생성
# - 5분 만료
# - 인증 완료 시 verified = true
class EmailVerification < ApplicationRecord
  EXPIRY_MINUTES = 5
  CODE_LENGTH = 6

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :code, presence: true

  # 유효한 인증 코드 (미인증 + 미만료)
  scope :valid, -> { where(verified: false).where("expires_at > ?", Time.current) }

  # 만료된 코드 정리
  scope :expired, -> { where("expires_at <= ?", Time.current) }

  # 6자리 영문+숫자 코드 생성 (대문자)
  def self.generate_code
    SecureRandom.alphanumeric(CODE_LENGTH).upcase
  end

  # 만료된 코드 삭제 (주기적 정리용)
  def self.cleanup_expired
    expired.destroy_all
  end

  def expired?
    expires_at < Time.current
  end

  def remaining_seconds
    [ (expires_at - Time.current).to_i, 0 ].max
  end
end
