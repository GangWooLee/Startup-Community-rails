# frozen_string_literal: true

require "test_helper"
require_relative "support/system_test_helpers"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Headless Chrome 설정
  # screen_size: 반응형 테스트를 위한 화면 크기
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # 공통 헬퍼 포함
  include SystemTestHelpers

  # Fixture 로드 - 필요한 것만 명시적으로 로드 (성능 최적화)
  # 각 시스템 테스트에서 추가 fixture 필요 시 개별 선언
  fixtures :users, :posts

  # 각 테스트 전 실행
  setup do
    # Capybara 기본 대기 시간 설정 (기본 2초 → 5초)
    Capybara.default_max_wait_time = 5
  end

  # 각 테스트 후 실행
  teardown do
    # 실패 시 자동 스크린샷은 Rails 기본 동작으로 처리됨
  end
end
