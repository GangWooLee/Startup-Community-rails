# frozen_string_literal: true

require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @oauth_user = users(:one)  # OAuth 사용자 (oauth_identities fixture 있음)
    @non_oauth_user = users(:three)  # OAuth 없는 일반 사용자
    @new_email = "newuser@example.com"
    # 기존 인증 코드 정리
    EmailVerification.destroy_all
  end

  # ===== create (인증 코드 발송) =====

  test "sends verification code for new email" do
    assert_difference "EmailVerification.count", 1 do
      post email_verifications_path, params: { email: @new_email }, as: :json
    end

    assert_response :success
    json = response.parsed_body

    assert json["success"]
    assert_equal "인증 코드를 발송했습니다.", json["message"]
    assert_equal EmailVerification::EXPIRY_MINUTES * 60, json["expires_in"]
  end

  test "rejects blank email" do
    assert_no_difference "EmailVerification.count" do
      post email_verifications_path, params: { email: "" }, as: :json
    end

    assert_response :unprocessable_entity
    json = response.parsed_body

    assert_not json["success"]
    assert_equal "올바른 이메일을 입력해주세요.", json["message"]
  end

  test "rejects invalid email format" do
    assert_no_difference "EmailVerification.count" do
      post email_verifications_path, params: { email: "not-an-email" }, as: :json
    end

    assert_response :unprocessable_entity
    json = response.parsed_body

    assert_not json["success"]
    assert_equal "올바른 이메일을 입력해주세요.", json["message"]
  end

  test "rejects already registered email for non-OAuth user" do
    # 기존 비 OAuth 사용자 (user :three는 oauth_identities 없음)
    assert_not @non_oauth_user.oauth_user?, "User :three should not be an OAuth user"

    assert_no_difference "EmailVerification.count" do
      post email_verifications_path, params: { email: @non_oauth_user.email }, as: :json
    end

    assert_response :unprocessable_entity
    json = response.parsed_body

    assert_not json["success"]
    assert_equal "이미 가입된 이메일입니다.", json["message"]
  end

  test "allows already registered email for OAuth user" do
    # OAuth 사용자 (user :one은 Google OAuth 있음)
    assert @oauth_user.oauth_user?, "User :one should be an OAuth user"

    assert_difference "EmailVerification.count", 1 do
      post email_verifications_path, params: { email: @oauth_user.email }, as: :json
    end

    assert_response :success
  end

  test "invalidates previous verification codes for same email" do
    # 첫 번째 코드 생성
    EmailVerification.create!(
      email: @new_email,
      code: "OLD123",
      expires_at: 5.minutes.from_now
    )

    # 두 번째 요청
    post email_verifications_path, params: { email: @new_email }, as: :json
    assert_response :success

    # 이전 코드는 삭제되어야 함
    assert_equal 1, EmailVerification.where(email: @new_email).count
    assert_nil EmailVerification.find_by(email: @new_email, code: "OLD123")
  end

  test "normalizes email to lowercase" do
    post email_verifications_path, params: { email: "TEST@EXAMPLE.COM" }, as: :json
    assert_response :success

    verification = EmailVerification.last
    assert_equal "test@example.com", verification.email
  end

  # ===== verify (인증 코드 확인) =====

  test "verifies correct code" do
    verification = EmailVerification.create!(
      email: @new_email,
      code: "ABC123",
      expires_at: 5.minutes.from_now
    )

    post verify_email_verifications_path, params: { email: @new_email, code: "ABC123" }, as: :json

    assert_response :success
    json = response.parsed_body

    assert json["success"]
    assert_equal "인증이 완료되었습니다.", json["message"]

    verification.reload
    assert verification.verified
  end

  test "rejects incorrect code" do
    EmailVerification.create!(
      email: @new_email,
      code: "ABC123",
      expires_at: 5.minutes.from_now
    )

    post verify_email_verifications_path, params: { email: @new_email, code: "WRONG1" }, as: :json

    assert_response :unprocessable_entity
    json = response.parsed_body

    assert_not json["success"]
    assert_match /올바르지 않거나 만료/, json["message"]
  end

  test "rejects expired code" do
    EmailVerification.create!(
      email: @new_email,
      code: "ABC123",
      expires_at: 1.minute.ago  # 만료됨
    )

    post verify_email_verifications_path, params: { email: @new_email, code: "ABC123" }, as: :json

    assert_response :unprocessable_entity
    json = response.parsed_body

    assert_not json["success"]
    assert_match /올바르지 않거나 만료/, json["message"]
  end

  test "rejects already verified code" do
    EmailVerification.create!(
      email: @new_email,
      code: "ABC123",
      expires_at: 5.minutes.from_now,
      verified: true  # 이미 인증됨
    )

    post verify_email_verifications_path, params: { email: @new_email, code: "ABC123" }, as: :json

    assert_response :unprocessable_entity
    json = response.parsed_body

    assert_not json["success"]
  end

  test "rejects blank email or code" do
    post verify_email_verifications_path, params: { email: "", code: "" }, as: :json

    assert_response :unprocessable_entity
    json = response.parsed_body

    assert_not json["success"]
    assert_equal "이메일과 인증 코드를 입력해주세요.", json["message"]
  end

  test "normalizes code to uppercase" do
    EmailVerification.create!(
      email: @new_email,
      code: "ABC123",
      expires_at: 5.minutes.from_now
    )

    # 소문자로 입력해도 인증 성공
    post verify_email_verifications_path, params: { email: @new_email, code: "abc123" }, as: :json

    assert_response :success
    json = response.parsed_body

    assert json["success"]
  end

  # ===== 보안 테스트 =====

  test "does not expose verification code in response" do
    post email_verifications_path, params: { email: @new_email }, as: :json
    assert_response :success

    json = response.parsed_body

    # 응답에 코드가 포함되어 있지 않아야 함
    assert_nil json["code"]
    assert_not json.to_s.include?(EmailVerification.last.code)
  end

  test "generates unique 6-character alphanumeric code" do
    post email_verifications_path, params: { email: @new_email }, as: :json
    assert_response :success

    verification = EmailVerification.last
    assert_equal EmailVerification::CODE_LENGTH, verification.code.length
    assert_match(/\A[A-Z0-9]+\z/, verification.code)
  end
end
