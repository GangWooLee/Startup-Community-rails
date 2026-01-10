# frozen_string_literal: true

module Payments
  # 토스페이먼츠 웹훅 서명 검증 서비스
  #
  # 보안:
  # - HMAC-SHA256 서명 검증
  # - Production에서는 webhook_secret 필수
  # - Development/Test에서는 미설정 시 경고 후 허용
  #
  # 사용 예:
  #   verifier = Payments::WebhookSignatureVerifier.new(payload, signature)
  #   if verifier.valid?
  #     # 서명 유효
  #   else
  #     # 서명 무효
  #   end
  class WebhookSignatureVerifier
    attr_reader :payload, :signature

    def initialize(payload, signature)
      @payload = payload
      @signature = signature
    end

    def valid?
      secret = webhook_secret

      if secret.blank?
        handle_missing_secret
      else
        verify_signature(secret)
      end
    end

    private

    # webhook_secret 미설정 시 처리
    def handle_missing_secret
      if Rails.env.production?
        # Production에서는 webhook_secret 필수
        Rails.logger.error "[Payments::WebhookSignatureVerifier] SECURITY: webhook_secret not configured in production. Rejecting webhook."
        false
      else
        # Development/Test에서는 경고만 출력하고 허용
        Rails.logger.warn "[Payments::WebhookSignatureVerifier] webhook_secret not configured. Skipping signature verification (development only)."
        true
      end
    end

    # 서명 검증 수행 (HMAC-SHA256)
    # 토스페이먼츠 공식 문서: https://docs.tosspayments.com/guides/webhook#서명-검증
    def verify_signature(secret)
      return false if signature.blank?

      expected_signature = OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha256"),
        secret,
        payload
      )

      # 타이밍 공격 방지를 위한 secure_compare 사용
      valid = ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)

      unless valid
        Rails.logger.warn "[Payments::WebhookSignatureVerifier] Invalid signature"
      end

      valid
    end

    # 웹훅 시크릿 키
    def webhook_secret
      Rails.application.credentials.dig(:toss, :webhook_secret)
    end
  end
end
