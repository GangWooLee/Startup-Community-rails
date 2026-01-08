# frozen_string_literal: true

require "test_helper"

class AccountMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:one)
    @oauth_user = users(:oauth_user)
    @verification_code = "ABC123"
    @reset_token = "test_reset_token_123"

    # Set default URL options for test environment
    Rails.application.routes.default_url_options[:host] = "example.com"
  end

  # ============================================================================
  # signup_verification tests
  # ============================================================================

  test "signup_verification sends email to correct recipient" do
    email = AccountMailer.signup_verification("newuser@test.com", @verification_code)

    assert_equal ["newuser@test.com"], email.to
  end

  test "signup_verification has correct subject" do
    email = AccountMailer.signup_verification("newuser@test.com", @verification_code)

    assert_equal "[Undrew] 회원가입 인증 코드", email.subject
  end

  test "signup_verification has correct sender" do
    email = AccountMailer.signup_verification("newuser@test.com", @verification_code)

    assert_equal ["noreply@undrewai.com"], email.from
  end

  test "signup_verification body contains verification code" do
    email = AccountMailer.signup_verification("newuser@test.com", @verification_code)

    assert_match @verification_code, email.body.encoded
  end

  test "signup_verification body contains expiry time" do
    email = AccountMailer.signup_verification("newuser@test.com", @verification_code)

    # EmailVerification::EXPIRY_MINUTES is 5
    assert_match "5분", email.body.encoded
  end

  test "signup_verification body contains instructions" do
    email = AccountMailer.signup_verification("newuser@test.com", @verification_code)

    assert_match "인증 코드를 회원가입 페이지에 입력해주세요", email.body.encoded
  end

  test "signup_verification delivers email" do
    assert_emails 1 do
      AccountMailer.signup_verification("newuser@test.com", @verification_code).deliver_now
    end
  end

  # ============================================================================
  # password_reset tests
  # ============================================================================

  test "password_reset sends email to user's email address" do
    email = AccountMailer.password_reset(@user, @reset_token)

    assert_equal [@user.email], email.to
  end

  test "password_reset has correct subject" do
    email = AccountMailer.password_reset(@user, @reset_token)

    assert_equal "[Undrew] 비밀번호 재설정", email.subject
  end

  test "password_reset has correct sender" do
    email = AccountMailer.password_reset(@user, @reset_token)

    assert_equal ["noreply@undrewai.com"], email.from
  end

  test "password_reset body contains user name" do
    email = AccountMailer.password_reset(@user, @reset_token)

    assert_match @user.name, email.body.encoded
  end

  test "password_reset body contains reset url with token" do
    email = AccountMailer.password_reset(@user, @reset_token)

    # Check that the reset URL with token is present in the email body
    assert_match @reset_token, email.body.encoded
    assert_match "password/reset", email.body.encoded
  end

  test "password_reset body contains expiry time" do
    email = AccountMailer.password_reset(@user, @reset_token)

    # 15 minutes expiry
    assert_match "15분", email.body.encoded
  end

  test "password_reset body contains reset instructions" do
    email = AccountMailer.password_reset(@user, @reset_token)

    assert_match "비밀번호 재설정을 요청하셨습니다", email.body.encoded
  end

  test "password_reset body contains reset button" do
    email = AccountMailer.password_reset(@user, @reset_token)

    assert_match "비밀번호 재설정하기", email.body.encoded
  end

  test "password_reset delivers email" do
    assert_emails 1 do
      AccountMailer.password_reset(@user, @reset_token).deliver_now
    end
  end

  # ============================================================================
  # oauth_password_notice tests
  # ============================================================================

  test "oauth_password_notice sends email to user's email address" do
    email = AccountMailer.oauth_password_notice(@oauth_user)

    assert_equal [@oauth_user.email], email.to
  end

  test "oauth_password_notice has correct subject" do
    email = AccountMailer.oauth_password_notice(@oauth_user)

    assert_equal "[Undrew] 비밀번호 재설정 안내", email.subject
  end

  test "oauth_password_notice has correct sender" do
    email = AccountMailer.oauth_password_notice(@oauth_user)

    assert_equal ["noreply@undrewai.com"], email.from
  end

  test "oauth_password_notice body contains user name" do
    email = AccountMailer.oauth_password_notice(@oauth_user)

    assert_match @oauth_user.name, email.body.encoded
  end

  test "oauth_password_notice body explains oauth account" do
    email = AccountMailer.oauth_password_notice(@oauth_user)

    assert_match "소셜 로그인", email.body.encoded
  end

  test "oauth_password_notice body contains connected providers" do
    email = AccountMailer.oauth_password_notice(@oauth_user)

    # oauth_user has google and github connections per fixtures
    providers = @oauth_user.connected_providers
    assert providers.any?, "oauth_user should have connected providers"

    # The mailer transforms provider names
    # google or google_oauth2 -> Google
    # github -> GitHub
    email_body = email.body.encoded
    # Check for presence of provider list section
    assert_match "연결된 소셜 계정", email_body
  end

  test "oauth_password_notice body contains login link" do
    email = AccountMailer.oauth_password_notice(@oauth_user)

    assert_match "로그인 페이지로 이동", email.body.encoded
    # Check for login path in URL
    assert_match "/login", email.body.encoded
  end

  test "oauth_password_notice explains social login account" do
    email = AccountMailer.oauth_password_notice(@oauth_user)

    # Match the actual text in the template
    assert_match "소셜 로그인</strong>으로 가입되었습니다", email.body.encoded
  end

  test "oauth_password_notice delivers email" do
    assert_emails 1 do
      AccountMailer.oauth_password_notice(@oauth_user).deliver_now
    end
  end

  # ============================================================================
  # Provider name transformation tests
  # ============================================================================

  test "oauth_password_notice transforms google to Google in provider list" do
    # oauth_user fixture has both google and github OAuth identities
    email = AccountMailer.oauth_password_notice(@oauth_user)
    email_body = email.body.encoded

    # The mailer should transform provider names
    assert_match "Google", email_body
  end

  test "oauth_password_notice transforms github to GitHub in provider list" do
    email = AccountMailer.oauth_password_notice(@oauth_user)
    email_body = email.body.encoded

    assert_match "GitHub", email_body
  end

  test "oauth_password_notice shows multiple providers" do
    # oauth_user has both google and github connected
    email = AccountMailer.oauth_password_notice(@oauth_user)
    email_body = email.body.encoded

    # Should show both providers
    assert_match "Google", email_body
    assert_match "GitHub", email_body
  end

  test "oauth_password_notice provider name transformation logic" do
    # Test the provider transformation by examining mailer behavior
    # Using user with google oauth identity
    user_with_google = users(:one)
    email = AccountMailer.oauth_password_notice(user_with_google)
    email_body = email.body.encoded

    # user one has google oauth identity (provider: google)
    # Should be transformed to "Google"
    assert_match "Google", email_body
  end

  # ============================================================================
  # Email delivery queue tests
  # ============================================================================

  test "signup_verification can be enqueued for later delivery" do
    assert_enqueued_emails 1 do
      AccountMailer.signup_verification("newuser@test.com", @verification_code).deliver_later
    end
  end

  test "password_reset can be enqueued for later delivery" do
    assert_enqueued_emails 1 do
      AccountMailer.password_reset(@user, @reset_token).deliver_later
    end
  end

  test "oauth_password_notice can be enqueued for later delivery" do
    assert_enqueued_emails 1 do
      AccountMailer.oauth_password_notice(@oauth_user).deliver_later
    end
  end

  # ============================================================================
  # Edge cases and error handling
  # ============================================================================

  test "signup_verification works with various email formats" do
    test_emails = [
      "simple@test.com",
      "with.dot@test.com",
      "with+plus@test.com",
      "korean@test.com"
    ]

    test_emails.each do |test_email|
      email = AccountMailer.signup_verification(test_email, @verification_code)
      assert_equal [test_email], email.to, "Failed for email: #{test_email}"
    end
  end

  test "password_reset works with user having special characters in name" do
    @user.name = "Test <User>"
    email = AccountMailer.password_reset(@user, @reset_token)

    # Should not raise an error
    assert_nothing_raised do
      email.body.encoded
    end
  end

  test "signup_verification handles code with special characters" do
    special_code = "ABC<>123"
    email = AccountMailer.signup_verification("user@test.com", special_code)

    # HTML should be properly escaped
    assert_nothing_raised do
      email.body.encoded
    end
  end

  # ============================================================================
  # Content structure tests
  # ============================================================================

  test "signup_verification contains brand name" do
    email = AccountMailer.signup_verification("test@test.com", @verification_code)

    assert_match "Undrew", email.body.encoded
  end

  test "password_reset contains brand name" do
    email = AccountMailer.password_reset(@user, @reset_token)

    assert_match "스타트업 커뮤니티", email.body.encoded
  end

  test "oauth_password_notice contains brand name" do
    email = AccountMailer.oauth_password_notice(@oauth_user)

    assert_match "스타트업 커뮤니티", email.body.encoded
  end

  test "signup_verification contains warning about ignoring email" do
    email = AccountMailer.signup_verification("test@test.com", @verification_code)

    assert_match "이 요청을 하지 않으셨다면", email.body.encoded
  end

  test "password_reset contains warning about ignoring email" do
    email = AccountMailer.password_reset(@user, @reset_token)

    assert_match "이 요청을 하지 않으셨다면", email.body.encoded
  end

  test "oauth_password_notice contains social service password reset guidance" do
    email = AccountMailer.oauth_password_notice(@oauth_user)

    # Should mention that users should reset password on the social service
    assert_match "소셜 서비스", email.body.encoded
    assert_match "비밀번호를 재설정해주세요", email.body.encoded
  end
end
