# frozen_string_literal: true

# FCM (Firebase Cloud Messaging) 푸시 알림 서비스
#
# FCM HTTP v1 API를 사용하여 iOS/Android 앱에 푸시 알림을 전송합니다.
# Google Cloud Service Account 인증 방식 사용.
#
# @example 단일 디바이스 전송
#   PushNotifications::FcmService.new.send_to_device(
#     device: device,
#     title: "새 메시지",
#     body: "홍길동님이 메시지를 보냈습니다.",
#     data: { chat_room_id: "123" }
#   )
#
# @example 사용자의 모든 디바이스 전송
#   PushNotifications::FcmService.new.send_to_user(
#     user: user,
#     title: "새 댓글",
#     body: "게시글에 댓글이 달렸습니다."
#   )
#
module PushNotifications
  class FcmService
    # FCM API 엔드포인트 (HTTP v1)
    FCM_BASE_URL = "https://fcm.googleapis.com/v1/projects"
    # 토큰 만료 시간 (1시간, 여유 두고 55분으로 설정)
    TOKEN_EXPIRY_SECONDS = 55 * 60

    class FcmError < StandardError; end
    class InvalidTokenError < FcmError; end
    class QuotaExceededError < FcmError; end

    def initialize
      @project_id = Rails.application.credentials.dig(:firebase, :project_id)
      @credentials = load_credentials
    end

    # 단일 디바이스에 푸시 전송
    #
    # @param device [Device] 대상 디바이스
    # @param title [String] 알림 제목
    # @param body [String] 알림 본문
    # @param data [Hash] 추가 데이터 (선택)
    # @return [Hash] FCM 응답
    def send_to_device(device:, title:, body:, data: {})
      return { success: false, error: "FCM not configured" } unless configured?

      message = build_message(
        token: device.token,
        platform: device.platform,
        title: title,
        body: body,
        data: data
      )

      send_message(message)
    rescue InvalidTokenError => e
      # 유효하지 않은 토큰은 비활성화
      device.disable!
      Rails.logger.warn "[FCM] Invalid token for device #{device.id}: #{e.message}"
      { success: false, error: "Invalid token", device_disabled: true }
    end

    # 사용자의 모든 활성 디바이스에 푸시 전송
    #
    # @param user [User] 대상 사용자
    # @param title [String] 알림 제목
    # @param body [String] 알림 본문
    # @param data [Hash] 추가 데이터 (선택)
    # @return [Array<Hash>] 각 디바이스 전송 결과
    def send_to_user(user:, title:, body:, data: {})
      devices = user.devices.enabled.recently_used

      devices.map do |device|
        result = send_to_device(device: device, title: title, body: body, data: data)
        { device_id: device.id, **result }
      end
    end

    # FCM이 설정되어 있는지 확인
    def configured?
      @project_id.present? && @credentials.present?
    end

    private

    # Service Account JSON 로드
    def load_credentials
      credentials_json = Rails.application.credentials.dig(:firebase, :service_account_json)
      return nil unless credentials_json.present?

      JSON.parse(credentials_json)
    rescue JSON::ParserError => e
      Rails.logger.error "[FCM] Invalid service account JSON: #{e.message}"
      nil
    end

    # FCM 메시지 구조 생성
    def build_message(token:, platform:, title:, body:, data:)
      message = {
        message: {
          token: token,
          notification: {
            title: title,
            body: body
          },
          data: data.transform_values(&:to_s)
        }
      }

      # 플랫폼별 설정 추가
      case platform
      when "ios"
        message[:message][:apns] = {
          payload: {
            aps: {
              sound: "default",
              badge: 1
            }
          }
        }
      when "android"
        message[:message][:android] = {
          priority: "high",
          notification: {
            sound: "default",
            channel_id: "default"
          }
        }
      end

      message
    end

    # FCM API 호출
    def send_message(message)
      response = connection.post(fcm_endpoint) do |req|
        req.headers["Authorization"] = "Bearer #{access_token}"
        req.headers["Content-Type"] = "application/json"
        req.body = message.to_json
      end

      handle_response(response)
    rescue Faraday::Error => e
      Rails.logger.error "[FCM] Request failed: #{e.message}"
      { success: false, error: e.message }
    end

    # FCM 응답 처리
    def handle_response(response)
      case response.status
      when 200
        { success: true, message_id: JSON.parse(response.body)["name"] }
      when 400
        error = JSON.parse(response.body)["error"]
        Rails.logger.warn "[FCM] Bad request: #{error}"
        { success: false, error: "Bad request" }
      when 401
        # 토큰 갱신 후 재시도
        @access_token = nil
        { success: false, error: "Auth failed, retry needed" }
      when 404
        # 토큰이 유효하지 않음 (앱 삭제 등)
        raise InvalidTokenError, "Token not found"
      when 429
        raise QuotaExceededError, "Rate limit exceeded"
      else
        error_body = begin
          JSON.parse(response.body)
        rescue StandardError
          response.body
        end
        Rails.logger.error "[FCM] Unexpected response #{response.status}: #{error_body}"
        { success: false, error: "Unexpected error" }
      end
    end

    # FCM API 엔드포인트
    def fcm_endpoint
      "#{FCM_BASE_URL}/#{@project_id}/messages:send"
    end

    # Faraday HTTP 클라이언트
    def connection
      @connection ||= Faraday.new do |f|
        f.request :url_encoded
        f.adapter Faraday.default_adapter
        f.options.timeout = 10
        f.options.open_timeout = 5
      end
    end

    # Google OAuth 2.0 액세스 토큰 (캐시)
    def access_token
      return @access_token if @access_token && !token_expired?

      @access_token = fetch_access_token
      @token_fetched_at = Time.current
      @access_token
    end

    # 토큰 만료 여부
    def token_expired?
      return true unless @token_fetched_at

      Time.current - @token_fetched_at > TOKEN_EXPIRY_SECONDS
    end

    # Google OAuth 2.0 액세스 토큰 발급
    def fetch_access_token
      return nil unless @credentials

      # JWT 생성
      jwt_token = generate_jwt

      # 토큰 교환
      response = Faraday.post("https://oauth2.googleapis.com/token") do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(
          grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
          assertion: jwt_token
        )
      end

      if response.status == 200
        JSON.parse(response.body)["access_token"]
      else
        Rails.logger.error "[FCM] Token fetch failed: #{response.body}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "[FCM] Token fetch error: #{e.message}"
      nil
    end

    # JWT 생성 (Service Account 인증용)
    def generate_jwt
      header = { alg: "RS256", typ: "JWT" }

      now = Time.current.to_i
      claims = {
        iss: @credentials["client_email"],
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: "https://oauth2.googleapis.com/token",
        iat: now,
        exp: now + 3600
      }

      private_key = OpenSSL::PKey::RSA.new(@credentials["private_key"])

      segments = [
        Base64.urlsafe_encode64(header.to_json, padding: false),
        Base64.urlsafe_encode64(claims.to_json, padding: false)
      ]

      signing_input = segments.join(".")
      signature = private_key.sign(OpenSSL::Digest.new("SHA256"), signing_input)

      segments << Base64.urlsafe_encode64(signature, padding: false)
      segments.join(".")
    end
  end
end
