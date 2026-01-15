# frozen_string_literal: true

require "test_helper"

module Payments
  class WebhookSignatureVerifierTest < ActiveSupport::TestCase
    setup do
      @webhook_secret = "test_webhook_secret_key"
      @payload = '{"eventType":"PAYMENT_STATUS_CHANGED","data":{"paymentKey":"pk_test_123"}}'
    end

    # ============================================================================
    # Valid Signature Tests
    # ============================================================================

    test "returns true for valid signature" do
      expected_signature = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha256"),
        @webhook_secret,
        @payload
      )

      verifier = Payments::WebhookSignatureVerifier.new(@payload, expected_signature)

      # webhook_secret이 설정된 상태를 모킹
      Rails.application.credentials.stub(:dig, ->(*keys) {
        keys == [ :toss, :webhook_secret ] ? @webhook_secret : nil
      }) do
        assert verifier.valid?
      end
    end

    test "returns false for invalid signature" do
      invalid_signature = "invalid_signature_hash"

      verifier = Payments::WebhookSignatureVerifier.new(@payload, invalid_signature)

      Rails.application.credentials.stub(:dig, ->(*keys) {
        keys == [ :toss, :webhook_secret ] ? @webhook_secret : nil
      }) do
        assert_not verifier.valid?
      end
    end

    test "returns false for blank signature when secret is configured" do
      verifier = Payments::WebhookSignatureVerifier.new(@payload, "")

      Rails.application.credentials.stub(:dig, ->(*keys) {
        keys == [ :toss, :webhook_secret ] ? @webhook_secret : nil
      }) do
        assert_not verifier.valid?
      end
    end

    test "returns false for nil signature when secret is configured" do
      verifier = Payments::WebhookSignatureVerifier.new(@payload, nil)

      Rails.application.credentials.stub(:dig, ->(*keys) {
        keys == [ :toss, :webhook_secret ] ? @webhook_secret : nil
      }) do
        assert_not verifier.valid?
      end
    end

    # ============================================================================
    # Missing Secret Tests - Development/Test Environment
    # ============================================================================

    test "returns true in development when webhook_secret is not configured" do
      verifier = Payments::WebhookSignatureVerifier.new(@payload, "any_signature")

      # webhook_secret이 nil인 상태
      Rails.application.credentials.stub(:dig, ->(*) { nil }) do
        # 현재 테스트 환경에서는 true를 반환해야 함
        assert verifier.valid?
      end
    end

    # ============================================================================
    # Missing Secret Tests - Production Environment
    # ============================================================================

    test "returns false in production when webhook_secret is not configured" do
      verifier = Payments::WebhookSignatureVerifier.new(@payload, "any_signature")

      Rails.application.credentials.stub(:dig, ->(*) { nil }) do
        Rails.stub(:env, ActiveSupport::StringInquirer.new("production")) do
          assert_not verifier.valid?
        end
      end
    end

    # ============================================================================
    # Timing Attack Prevention Tests
    # ============================================================================

    test "uses secure_compare for timing attack prevention" do
      # secure_compare가 코드에서 사용되는지 확인 (코드 검사)
      # 실제 메서드 호출 테스트는 모듈 stub 제한으로 인해 코드 리뷰로 대체
      source_code = File.read(Rails.root.join("app/services/payments/webhook_signature_verifier.rb"))

      assert_includes source_code, "secure_compare",
        "WebhookSignatureVerifier should use secure_compare for timing attack prevention"

      # 또한 서명 검증이 올바르게 동작하는지 확인
      expected_signature = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha256"),
        @webhook_secret,
        @payload
      )

      verifier = Payments::WebhookSignatureVerifier.new(@payload, expected_signature)

      Rails.application.credentials.stub(:dig, ->(*keys) {
        keys == [ :toss, :webhook_secret ] ? @webhook_secret : nil
      }) do
        assert verifier.valid?
      end

      # 약간 다른 서명은 실패해야 함 (타이밍 공격 방지 검증)
      wrong_signature = expected_signature[0..-2] + "X"
      verifier2 = Payments::WebhookSignatureVerifier.new(@payload, wrong_signature)

      Rails.application.credentials.stub(:dig, ->(*keys) {
        keys == [ :toss, :webhook_secret ] ? @webhook_secret : nil
      }) do
        assert_not verifier2.valid?
      end
    end

    # ============================================================================
    # HMAC-SHA256 Signature Generation Tests
    # ============================================================================

    test "generates correct HMAC-SHA256 signature" do
      # 알려진 테스트 값으로 서명 검증
      test_payload = "test_payload"
      test_secret = "test_secret"

      expected = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha256"),
        test_secret,
        test_payload
      )

      verifier = Payments::WebhookSignatureVerifier.new(test_payload, expected)

      Rails.application.credentials.stub(:dig, ->(*keys) {
        keys == [ :toss, :webhook_secret ] ? test_secret : nil
      }) do
        assert verifier.valid?
      end
    end
  end
end
