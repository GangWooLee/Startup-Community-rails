# frozen_string_literal: true

require "test_helper"

class EmailVerificationTest < ActiveSupport::TestCase
  # ─────────────────────────────────────────────────
  # Validation Tests
  # ─────────────────────────────────────────────────

  test "valid email verification" do
    verification = EmailVerification.new(
      email: "test@example.com",
      code: "ABC123",
      expires_at: 5.minutes.from_now
    )
    assert verification.valid?
  end

  test "requires email" do
    verification = EmailVerification.new(code: "ABC123", expires_at: 5.minutes.from_now)
    assert_not verification.valid?
    assert verification.errors[:email].any?
  end

  test "requires valid email format" do
    verification = EmailVerification.new(
      email: "invalid-email",
      code: "ABC123",
      expires_at: 5.minutes.from_now
    )
    assert_not verification.valid?
    assert verification.errors[:email].any?
  end

  test "requires code" do
    verification = EmailVerification.new(email: "test@example.com", expires_at: 5.minutes.from_now)
    assert_not verification.valid?
    assert verification.errors[:code].any?
  end

  # ─────────────────────────────────────────────────
  # Code Generation Tests
  # ─────────────────────────────────────────────────

  test "generate_code returns 6 character alphanumeric code" do
    code = EmailVerification.generate_code
    assert_equal 6, code.length
    assert_match /\A[A-Z0-9]+\z/, code
  end

  test "generate_code returns unique codes" do
    codes = 10.times.map { EmailVerification.generate_code }
    assert_equal 10, codes.uniq.size
  end

  # ─────────────────────────────────────────────────
  # Expiry Tests
  # ─────────────────────────────────────────────────

  test "expired? returns true when expires_at is in past" do
    verification = EmailVerification.new(
      email: "test@example.com",
      code: "ABC123",
      expires_at: 1.minute.ago
    )
    assert verification.expired?
  end

  test "expired? returns false when expires_at is in future" do
    verification = EmailVerification.new(
      email: "test@example.com",
      code: "ABC123",
      expires_at: 5.minutes.from_now
    )
    assert_not verification.expired?
  end

  test "remaining_seconds returns positive value when not expired" do
    verification = EmailVerification.new(
      email: "test@example.com",
      code: "ABC123",
      expires_at: 5.minutes.from_now
    )
    assert_operator verification.remaining_seconds, :>, 0
    assert_operator verification.remaining_seconds, :<=, 300
  end

  test "remaining_seconds returns 0 when expired" do
    verification = EmailVerification.new(
      email: "test@example.com",
      code: "ABC123",
      expires_at: 1.minute.ago
    )
    assert_equal 0, verification.remaining_seconds
  end

  # ─────────────────────────────────────────────────
  # Scope Tests
  # ─────────────────────────────────────────────────

  test "valid scope excludes expired verifications" do
    # Create expired verification
    expired = EmailVerification.create!(
      email: "expired@example.com",
      code: "ABC123",
      expires_at: 1.minute.ago,
      verified: false
    )

    # Create valid verification
    valid = EmailVerification.create!(
      email: "valid@example.com",
      code: "DEF456",
      expires_at: 5.minutes.from_now,
      verified: false
    )

    results = EmailVerification.valid
    assert_includes results, valid
    assert_not_includes results, expired
  end

  test "valid scope excludes verified verifications" do
    verified = EmailVerification.create!(
      email: "verified@example.com",
      code: "ABC123",
      expires_at: 5.minutes.from_now,
      verified: true
    )

    results = EmailVerification.valid
    assert_not_includes results, verified
  end

  test "expired scope includes only expired verifications" do
    expired = EmailVerification.create!(
      email: "expired@example.com",
      code: "ABC123",
      expires_at: 1.minute.ago
    )

    valid = EmailVerification.create!(
      email: "valid@example.com",
      code: "DEF456",
      expires_at: 5.minutes.from_now
    )

    results = EmailVerification.expired
    assert_includes results, expired
    assert_not_includes results, valid
  end

  # ─────────────────────────────────────────────────
  # Cleanup Tests
  # ─────────────────────────────────────────────────

  test "cleanup_expired destroys expired records" do
    EmailVerification.create!(
      email: "expired@example.com",
      code: "ABC123",
      expires_at: 1.minute.ago
    )

    assert_difference "EmailVerification.count", -1 do
      EmailVerification.cleanup_expired
    end
  end

  # ─────────────────────────────────────────────────
  # Constants Tests
  # ─────────────────────────────────────────────────

  test "EXPIRY_MINUTES is 5" do
    assert_equal 5, EmailVerification::EXPIRY_MINUTES
  end

  test "CODE_LENGTH is 6" do
    assert_equal 6, EmailVerification::CODE_LENGTH
  end
end
