# frozen_string_literal: true

# 사용자 세션 추적 기능
#
# 사용법:
#   user.active_sessions          # 현재 활성 세션
#   user.session_history          # 최근 세션 기록
#   user.has_active_session?      # 활성 세션 존재 여부
#   user.end_all_sessions!        # 모든 세션 강제 종료
#   user.login_count              # 로그인 횟수
#
module SessionTrackable
  extend ActiveSupport::Concern

  included do
    has_many :user_sessions, dependent: :destroy
  end

  # 현재 활성 세션 목록
  def active_sessions
    user_sessions.active
  end

  # 최근 세션 기록 (기본 20개)
  def session_history(limit: 20)
    user_sessions.recent.limit(limit)
  end

  # 활성 세션 존재 여부
  def has_active_session?
    user_sessions.active.exists?
  end

  # 모든 활성 세션 강제 종료
  #
  # @param reason [String] 종료 사유 (기본: "forced")
  def end_all_sessions!(reason: "forced")
    user_sessions.active.find_each { |s| s.end_session!(reason: reason) }
  end

  # 특정 세션 제외하고 모든 세션 종료 (다른 기기에서 로그아웃)
  #
  # @param except_token [String] 제외할 세션 토큰
  # @param reason [String] 종료 사유
  def end_other_sessions!(except_token:, reason: "forced")
    user_sessions.active.where.not(session_token: except_token).find_each do |s|
      s.end_session!(reason: reason)
    end
  end

  # 로그인 횟수
  #
  # @param since [Time, nil] 이 시간 이후의 로그인만 카운트
  # @return [Integer] 로그인 횟수
  def login_count(since: nil)
    scope = user_sessions
    scope = scope.where("logged_in_at >= ?", since) if since
    scope.count
  end

  # 최근 로그인 시간
  def last_login_at
    user_sessions.maximum(:logged_in_at)
  end

  # 가장 많이 사용한 로그인 방식
  def primary_login_method
    user_sessions
      .group(:login_method)
      .order("count_id DESC")
      .count(:id)
      .keys
      .first || "email"
  end

  # 최근 사용 기기 타입 목록
  def recent_device_types
    user_sessions.where.not(device_type: nil)
                 .distinct
                 .pluck(:device_type)
  end

  # 최근 접속 IP 목록 (중복 제거)
  def recent_ip_addresses(limit: 10)
    user_sessions.where.not(ip_address: nil)
                 .order(logged_in_at: :desc)
                 .limit(limit)
                 .distinct
                 .pluck(:ip_address)
  end
end
