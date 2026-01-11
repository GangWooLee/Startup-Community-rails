# frozen_string_literal: true

# SimpleCov must be loaded before Rails environment
require "simplecov"
SimpleCov.start "rails" do
  # Exclude non-application code
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/vendor/"
  add_filter "/bin/"

  # Group results for better visibility
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Helpers", "app/helpers"
  add_group "Services", "app/services"
  add_group "Jobs", "app/jobs"
  add_group "Mailers", "app/mailers"

  # Coverage Policy (2026-01-11 업데이트)
  #
  # 전략: 커버리지 하락 방지 + 점진적 개선
  # - coverage/ 폴더는 GitHub Actions Artifact로 업로드됨
  # - refuse_coverage_drop: 현재 커버리지보다 하락 시 CI 실패
  # - 목표: 현재(2.2%) → Phase 1(5%) → Phase 2(10%) → Phase 3(20%)
  #
  # 개선 우선순위:
  # 1. 인증/인가 로직 (100% 목표)
  # 2. 결제 로직 (100% 목표)
  # 3. 핵심 모델 validations (80% 목표)
  #
  # 커버리지 하락 방지 (리그레션 보호)
  refuse_coverage_drop

  # 점진적 최소 커버리지 목표 (달성 시 주석 해제)
  # minimum_coverage 5   # Phase 1: 달성 후 활성화
  # minimum_coverage 10  # Phase 2: 달성 후 활성화
  # minimum_coverage 20  # Phase 3: 달성 후 활성화
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# WebMock for HTTP request stubbing (AI API 등 외부 호출 격리)
require "webmock/minitest"
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: [
    "chromedriver.storage.googleapis.com",  # Selenium driver
    /selenium/,                              # Selenium grid
    /127\.0\.0\.1/,                          # localhost
    /localhost/                              # localhost
  ]
)

# OmniAuth 테스트 모드 활성화
OmniAuth.config.test_mode = true

# OmniAuth Mock 데이터
OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new({
  provider: "google",
  uid: "123456789",
  info: {
    email: "test@gmail.com",
    name: "Test Google User",
    image: "https://example.com/avatar.jpg"
  }
})

OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new({
  provider: "github",
  uid: "987654321",
  info: {
    email: "test@github.com",
    name: "Test GitHub User",
    nickname: "testuser",
    image: "https://github.com/avatar.jpg"
  }
})

# 테스트용 Custom Assertions
module CustomAssertions
  # 로그인 상태 확인
  def assert_logged_in
    assert session[:user_id].present?, "Expected user to be logged in"
  end

  # 로그아웃 상태 확인
  def assert_not_logged_in
    assert_nil session[:user_id], "Expected user to not be logged in"
  end

  # Flash 메시지 확인
  def assert_flash(type, message = nil)
    assert flash[type].present?, "Expected flash[:#{type}] to be present"
    if message
      assert_includes flash[type], message, "Expected flash[:#{type}] to include '#{message}'"
    end
  end

  # Flash 없음 확인
  def assert_no_flash(type)
    assert_nil flash[type], "Expected flash[:#{type}] to be nil"
  end

  # Turbo Stream 응답 확인
  def assert_turbo_stream(action:, target:)
    assert_match /turbo-stream action="#{action}" target="#{target}"/, @response.body,
      "Expected turbo-stream with action='#{action}' and target='#{target}'"
  end

  # 유효성 검증 에러 확인
  def assert_validation_error(record, attribute, message = nil)
    assert record.errors[attribute].any?, "Expected validation error on #{attribute}"
    if message
      assert record.errors[attribute].any? { |e| e.include?(message) },
        "Expected validation error '#{message}' on #{attribute}, got: #{record.errors[attribute].join(', ')}"
    end
  end

  # 레코드 저장 실패 확인
  def assert_not_saved(record)
    assert_not record.persisted?, "Expected record to not be saved"
  end

  # 레코드 삭제 확인
  def assert_destroyed(record)
    assert record.destroyed?, "Expected record to be destroyed"
    assert_nil record.class.find_by(id: record.id), "Expected record to not exist in database"
  end

  # 모델 카운트 변화 없음 확인
  def assert_no_difference_in(expression, &block)
    assert_no_difference expression, &block
  end
end

# AI API Mock 헬퍼
module AiMockHelpers
  # Gemini API 응답 Mock
  def mock_gemini_response(content)
    {
      "candidates" => [
        {
          "content" => {
            "parts" => [ { "text" => content } ]
          },
          "finishReason" => "STOP"
        }
      ]
    }
  end

  # AI 분석 결과 Mock
  def mock_analysis_result
    {
      summary: "이것은 테스트 아이디어입니다.",
      target_users: [ "초기 창업자", "대학생" ],
      market_analysis: {
        size: "1조원 규모",
        growth_rate: "연 15%",
        competitors: [ "경쟁사A", "경쟁사B" ]
      },
      strategy: {
        go_to_market: "온라인 마케팅 집중",
        differentiation: "사용자 경험 개선"
      },
      score: {
        feasibility: 80,
        market_potential: 75,
        innovation: 70,
        overall: 75
      }
    }
  end

  # Gemini API 호출 스텁 (WebMock 사용)
  def stub_gemini_api(response_content)
    stub_request(:post, %r{generativelanguage\.googleapis\.com})
      .to_return(
        status: 200,
        body: mock_gemini_response(response_content).to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Gemini API 에러 스텁
  def stub_gemini_api_error(status: 500, error_message: "Internal Server Error")
    stub_request(:post, %r{generativelanguage\.googleapis\.com})
      .to_return(status: status, body: { error: error_message }.to_json)
  end

  # AI 에이전트용 JSON 응답 스텁
  def stub_gemini_json_response(json_hash)
    json_content = "```json\n#{json_hash.to_json}\n```"
    stub_gemini_api(json_content)
  end
end

# Toss Payments Mock 헬퍼
module TossPaymentsMockHelpers
  # 결제 승인 성공 응답
  def mock_toss_approve_success(payment_key, order_id, amount)
    {
      "mId" => "test_merchant",
      "paymentKey" => payment_key,
      "orderId" => order_id,
      "status" => "DONE",
      "requestedAt" => Time.current.iso8601,
      "approvedAt" => Time.current.iso8601,
      "card" => {
        "issuerCode" => "11",
        "company" => "신한카드",
        "number" => "************1234",
        "cardType" => "CREDIT"
      },
      "totalAmount" => amount,
      "method" => "CARD",
      "receipt" => {
        "url" => "https://receipt.example.com/#{payment_key}"
      }
    }
  end

  # 결제 승인 실패 응답
  def mock_toss_approve_failure(code, message)
    {
      "code" => code,
      "message" => message
    }
  end

  # 결제 취소 성공 응답
  def mock_toss_cancel_success(payment_key, cancel_amount)
    {
      "paymentKey" => payment_key,
      "status" => "CANCELED",
      "cancels" => [
        {
          "cancelAmount" => cancel_amount,
          "canceledAt" => Time.current.iso8601,
          "cancelReason" => "사용자 요청"
        }
      ]
    }
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Custom assertions 포함
    include CustomAssertions
    include AiMockHelpers
    include TossPaymentsMockHelpers

    # 테스트용 비밀번호 상수
    TEST_PASSWORD = "test1234"

    # 테스트에서 사용할 기본 사용자 생성 헬퍼
    def create_test_user(overrides = {})
      User.create!({
        email: "test#{SecureRandom.hex(4)}@test.com",
        password: TEST_PASSWORD,
        name: "Test User"
      }.merge(overrides))
    end

    # 테스트용 게시글 생성 헬퍼
    def create_test_post(user, overrides = {})
      user.posts.create!({
        title: "Test Post",
        content: "Test content",
        status: :published,
        category: :free
      }.merge(overrides))
    end

    # 테스트용 외주 글 생성 헬퍼
    def create_outsourcing_post(user, category = :hiring, overrides = {})
      defaults = {
        title: "Test Outsourcing Post",
        content: "Looking for a developer",
        status: :published,
        category: category,
        service_type: "development",
        price: 1_000_000,
        price_negotiable: false
      }
      defaults[:work_type] = "remote" if category == :hiring
      user.posts.create!(defaults.merge(overrides))
    end
  end
end

class ActionDispatch::IntegrationTest
  include CustomAssertions
  include AiMockHelpers
  include TossPaymentsMockHelpers

  # 테스트용 비밀번호 상수
  TEST_PASSWORD = "test1234"

  # 사용자 로그인 헬퍼
  def log_in_as(user, remember_me: false)
    post login_path, params: {
      email: user.email,
      password: TEST_PASSWORD,
      remember_me: remember_me ? "1" : "0"
    }
  end

  # 관리자 로그인 헬퍼
  def log_in_as_admin
    admin = users(:admin) rescue create_admin_user
    log_in_as(admin)
    admin
  end

  # 관리자 사용자 생성
  def create_admin_user
    User.create!(
      email: "admin@test.com",
      password: TEST_PASSWORD,
      name: "Admin User",
      is_admin: true
    )
  end

  # 로그아웃 헬퍼
  def log_out
    delete logout_path
  end

  # 현재 로그인 사용자 확인
  def current_user
    User.find_by(id: session[:user_id])
  end

  # 인증 필수 페이지 접근 테스트 헬퍼
  def assert_requires_login(method, path, params = {})
    send(method, path, params: params)
    assert_redirected_to login_path
    assert_flash :alert
  end

  # JSON 응답 파싱 헬퍼
  def json_response
    JSON.parse(response.body)
  end
end

# 컨트롤러 테스트용 추가 헬퍼
class ActionController::TestCase
  include CustomAssertions

  TEST_PASSWORD = "test1234"

  def log_in_as(user)
    session[:user_id] = user.id
  end

  def log_out
    session.delete(:user_id)
  end

  def current_user
    User.find_by(id: session[:user_id])
  end
end
