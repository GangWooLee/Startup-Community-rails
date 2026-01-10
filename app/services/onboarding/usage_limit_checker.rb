# frozen_string_literal: true

module Onboarding
  # AI 분석 사용량 제한 확인 서비스
  #
  # 로그인 사용자와 비로그인 사용자(쿠키 기반)의 사용량을 통합 관리
  # 보너스 크레딧 포함 계산
  #
  # 사용 예:
  #   checker = Onboarding::UsageLimitChecker.new(user: current_user, cookies: cookies)
  #   checker.remaining    # 잔여 횟수
  #   checker.exceeded?    # 초과 여부
  #   checker.increment!   # 사용 횟수 증가 (비로그인용)
  class UsageLimitChecker
    MAX_FREE_ANALYSES = 5

    attr_reader :user, :cookies

    def initialize(user:, cookies:)
      @user = user
      @cookies = cookies
    end

    # 로그인 여부 확인
    def logged_in?
      user.present?
    end

    # 현재 사용 횟수 (비로그인 쿠키 + 로그인 DB 합산)
    def current_count
      guest_count = cookies[:guest_ai_usage_count].to_i

      if logged_in?
        user.idea_analyses.count + guest_count
      else
        guest_count
      end
    end

    # 사용자별 유효 limit (로그인: 사용자 설정, 비로그인: 기본값)
    def effective_limit
      if logged_in?
        user.effective_ai_limit
      else
        MAX_FREE_ANALYSES
      end
    end

    # 잔여 분석 횟수 (로그인: 보너스 포함, 비로그인: 쿠키 기반)
    def remaining
      if logged_in?
        user.ai_analyses_remaining
      else
        MAX_FREE_ANALYSES - cookies[:guest_ai_usage_count].to_i
      end
    end

    # 사용 횟수 초과 여부
    def exceeded?
      remaining <= 0
    end

    # 마지막 1회 남음 여부
    def last_one?
      remaining == 1
    end

    # 보너스 보유 여부 (UI 표시용)
    def has_bonus?
      logged_in? && user.ai_bonus_credits.to_i > 0
    end

    # 비로그인 사용자 쿠키 횟수 증가
    def increment_guest_count!
      return if logged_in?

      current = cookies[:guest_ai_usage_count].to_i
      cookies.permanent[:guest_ai_usage_count] = (current + 1).to_s
    end

    # 뷰에 필요한 통계 해시 반환
    def stats
      {
        remaining: remaining,
        effective_limit: effective_limit,
        has_bonus: has_bonus?
      }
    end
  end
end
