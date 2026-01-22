# frozen_string_literal: true

# 사용자 기기 (Push Notification 토큰 저장)
#
# 각 사용자의 모바일 기기 정보와 푸시 알림 토큰을 저장합니다.
# FCM (Firebase Cloud Messaging) 토큰을 사용하여 iOS/Android 모두 지원합니다.
#
# @example 디바이스 등록
#   Device.register(
#     user: current_user,
#     platform: "ios",
#     token: "fcm_token_here",
#     device_name: "iPhone 15 Pro",
#     app_version: "1.0.0"
#   )
#
class Device < ApplicationRecord
  # ==========================================================================
  # Constants
  # ==========================================================================
  PLATFORMS = %w[ios android].freeze
  # FCM 토큰 길이 범위 (실제 FCM 토큰은 약 150-200자, 여유 범위 설정)
  TOKEN_MIN_LENGTH = 50
  TOKEN_MAX_LENGTH = 1024

  # ==========================================================================
  # Associations
  # ==========================================================================
  belongs_to :user

  # ==========================================================================
  # Validations
  # ==========================================================================
  validates :platform, presence: true, inclusion: { in: PLATFORMS }
  validates :token, presence: true,
                    uniqueness: true,
                    length: { minimum: TOKEN_MIN_LENGTH, maximum: TOKEN_MAX_LENGTH }

  # ==========================================================================
  # Scopes
  # ==========================================================================
  scope :enabled, -> { where(enabled: true) }
  scope :ios, -> { where(platform: "ios") }
  scope :android, -> { where(platform: "android") }
  scope :recently_used, -> { where("last_used_at > ?", 30.days.ago) }

  # ==========================================================================
  # Class Methods
  # ==========================================================================

  # 디바이스 등록 또는 업데이트
  # 동일한 토큰이 있으면 업데이트, 없으면 생성
  #
  # @param user [User] 사용자
  # @param platform [String] 플랫폼 (ios, android)
  # @param token [String] FCM 토큰
  # @param device_name [String] 기기 이름 (선택)
  # @param app_version [String] 앱 버전 (선택)
  # @return [Device] 등록된 디바이스
  def self.register(user:, platform:, token:, device_name: nil, app_version: nil)
    device = find_or_initialize_by(token: token)
    device.assign_attributes(
      user: user,
      platform: platform,
      device_name: device_name,
      app_version: app_version,
      enabled: true,
      last_used_at: Time.current
    )
    device.save  # save (not save!) to allow controller to handle validation errors
    device
  end

  # ==========================================================================
  # Instance Methods
  # ==========================================================================

  def ios?
    platform == "ios"
  end

  def android?
    platform == "android"
  end

  # 마지막 사용 시간 갱신
  def touch_usage!
    update_column(:last_used_at, Time.current)
  end

  # 디바이스 비활성화 (로그아웃 시)
  def disable!
    update!(enabled: false)
  end
end
