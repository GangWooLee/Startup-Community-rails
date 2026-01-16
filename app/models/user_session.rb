# frozen_string_literal: true

# 사용자 로그인/로그아웃 기록
#
# 목적:
# - 관리자가 사용자의 접속 기록 추적
# - 강제 로그아웃 기능
# - 활성 사용자 통계
#
# 사용법:
#   UserSession.record_login(user:, method:, ip_address:, user_agent:)
#   user_session.end_session!(reason: "user_initiated")
#
class UserSession < ApplicationRecord
  # ==========================================================================
  # Associations
  # ==========================================================================
  belongs_to :user

  # ==========================================================================
  # Validations
  # ==========================================================================
  validates :session_token, presence: true, uniqueness: true
  validates :login_method, presence: true, inclusion: { in: %w[email google github] }
  validates :logged_in_at, presence: true

  # ==========================================================================
  # Callbacks
  # ==========================================================================
  before_validation :generate_session_token, on: :create
  before_validation :set_logged_in_at, on: :create
  before_validation :parse_device_type, on: :create

  # ==========================================================================
  # Scopes
  # ==========================================================================
  scope :active, -> { where(logged_out_at: nil) }
  scope :ended, -> { where.not(logged_out_at: nil) }
  scope :recent, -> { order(logged_in_at: :desc) }
  scope :by_login_method, ->(method) { where(login_method: method) }

  # ==========================================================================
  # Class Methods
  # ==========================================================================

  # 로그인 기록 생성
  #
  # @param user [User] 로그인한 사용자
  # @param method [String] 로그인 방식 (email, google, github)
  # @param ip_address [String, nil] IP 주소
  # @param user_agent [String, nil] User Agent
  # @param remember_me [Boolean] Remember Me 여부
  # @return [UserSession] 생성된 세션 기록
  def self.record_login(user:, method:, ip_address: nil, user_agent: nil, remember_me: false)
    create!(
      user: user,
      login_method: method,
      ip_address: ip_address,
      user_agent: user_agent,
      remember_me: remember_me,
      last_activity_at: Time.current
    )
  end

  # ==========================================================================
  # Instance Methods
  # ==========================================================================

  # 세션 종료 기록
  #
  # @param reason [String] 종료 사유 (user_initiated, session_expired, forced, admin_action)
  def end_session!(reason: "user_initiated")
    update!(
      logged_out_at: Time.current,
      logout_reason: reason
    )
  end

  # 활성 세션 여부
  def active?
    logged_out_at.nil?
  end

  # 세션 시간 (분)
  def duration_minutes
    return nil unless logged_out_at

    ((logged_out_at - logged_in_at) / 60).round
  end

  # 세션 시간 (포맷팅)
  def duration_formatted
    return "활성 중" if active?

    minutes = duration_minutes
    return "1분 미만" if minutes < 1

    if minutes < 60
      "#{minutes}분"
    elsif minutes < 1440  # 24시간
      "#{minutes / 60}시간 #{minutes % 60}분"
    else
      "#{minutes / 1440}일 #{(minutes % 1440) / 60}시간"
    end
  end

  # 마지막 활동 업데이트
  def touch_activity!
    update_column(:last_activity_at, Time.current)
  end

  # IP 주소 마스킹 (프라이버시 보호)
  def masked_ip_address
    return "N/A" if ip_address.blank?

    parts = ip_address.split(".")
    return ip_address unless parts.size == 4

    "#{parts[0]}.#{parts[1]}.***.***"
  end

  private

  def generate_session_token
    self.session_token ||= SecureRandom.uuid
  end

  def set_logged_in_at
    self.logged_in_at ||= Time.current
  end

  # User Agent에서 디바이스 타입 파싱
  def parse_device_type
    return if user_agent.blank?

    ua = user_agent.downcase
    self.device_type = if ua.include?("mobile") || ua.include?("android") || ua.include?("iphone")
                         "mobile"
    elsif ua.include?("tablet") || ua.include?("ipad")
                         "tablet"
    else
                         "desktop"
    end
  end
end
