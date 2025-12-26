# 토스페이먼츠 API 기본 서비스 클래스
# 모든 토스페이먼츠 서비스의 베이스 클래스
module TossPayments
  class BaseService
    # 토스페이먼츠 API 엔드포인트
    API_BASE_URL = "https://api.tosspayments.com".freeze
    API_VERSION = "v1".freeze

    # 에러 클래스 정의
    class Error < StandardError
      attr_reader :code, :message, :response

      def initialize(code:, message:, response: nil)
        @code = code
        @message = message
        @response = response
        super("#{code}: #{message}")
      end
    end

    class AuthenticationError < Error; end
    class ValidationError < Error; end
    class PaymentError < Error; end
    class NetworkError < Error; end

    def initialize
      @client_key = credentials[:client_key]
      @secret_key = credentials[:secret_key]

      validate_credentials!
    end

    private

    # Rails credentials에서 토스페이먼츠 설정 가져오기
    # 설정 방법:
    #   EDITOR="code --wait" bin/rails credentials:edit
    #   또는
    #   EDITOR=vim bin/rails credentials:edit
    #
    # 추가할 내용:
    #   toss:
    #     client_key: "test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm"
    #     secret_key: "test_gsk_docs_OaPz8L5KdmQXkzRz3y47BMw6"
    #     webhook_secret: "your_webhook_secret_here"
    def credentials
      @credentials ||= Rails.application.credentials.toss || {}
    end

    # 자격증명 검증
    # Production에서는 credentials 필수, Development/Test에서는 테스트 키 폴백
    def validate_credentials!
      if Rails.env.production?
        validate_production_credentials!
      else
        validate_development_credentials!
      end
    end

    # Production 환경: credentials 필수
    def validate_production_credentials!
      if @client_key.blank?
        raise ConfigurationError, "TossPayments client_key가 설정되지 않았습니다. Rails credentials에 toss.client_key를 추가하세요."
      end

      if @secret_key.blank?
        raise ConfigurationError, "TossPayments secret_key가 설정되지 않았습니다. Rails credentials에 toss.secret_key를 추가하세요."
      end
    end

    # Development/Test 환경: 테스트 키 폴백 허용
    def validate_development_credentials!
      # 테스트 키 (토스페이먼츠 공식 테스트 키)
      test_client_key = "test_gck_docs_Ovk5rk1EwkEbP0W43n07xlzm"
      test_secret_key = "test_gsk_docs_OaPz8L5KdmQXkzRz3y47BMw6"

      if @client_key.blank?
        Rails.logger.warn "[TossPayments] Client key missing. Using test key (development only)."
        @client_key = test_client_key
      end

      if @secret_key.blank?
        Rails.logger.warn "[TossPayments] Secret key missing. Using test key (development only)."
        @secret_key = test_secret_key
      end
    end

    # 설정 에러 클래스
    class ConfigurationError < StandardError; end

    # Base64 인코딩된 인증 헤더 생성 (Secret Key 사용)
    def authorization_header
      encoded = Base64.strict_encode64("#{@secret_key}:")
      "Basic #{encoded}"
    end

    # API 요청 헤더
    def request_headers
      {
        "Authorization" => authorization_header,
        "Content-Type" => "application/json"
      }
    end

    # HTTP POST 요청
    def post(path, body = {})
      url = "#{API_BASE_URL}/#{API_VERSION}#{path}"

      Rails.logger.info "[TossPayments] POST #{url}"
      Rails.logger.debug "[TossPayments] Request body: #{body.except(:paymentKey).to_json}"

      response = http_client.post(url, body.to_json, request_headers)
      handle_response(response)
    rescue StandardError => e
      handle_network_error(e)
    end

    # HTTP GET 요청
    def get(path)
      url = "#{API_BASE_URL}/#{API_VERSION}#{path}"

      Rails.logger.info "[TossPayments] GET #{url}"

      response = http_client.get(url, request_headers)
      handle_response(response)
    rescue StandardError => e
      handle_network_error(e)
    end

    # HTTP 클라이언트 (Net::HTTP 래퍼)
    def http_client
      @http_client ||= HttpClient.new
    end

    # 응답 처리
    def handle_response(response)
      body = parse_json(response.body)

      case response.code.to_i
      when 200..299
        Result.success(body)
      when 400
        handle_error(ValidationError, body)
      when 401
        handle_error(AuthenticationError, body)
      else
        handle_error(PaymentError, body)
      end
    end

    # JSON 파싱 (안전하게)
    def parse_json(body)
      return {} if body.blank?

      JSON.parse(body, symbolize_names: true)
    rescue JSON::ParserError => e
      Rails.logger.error "[TossPayments] JSON parse error: #{e.message}"
      {}
    end

    # 에러 처리
    def handle_error(error_class, body)
      code = body[:code] || "UNKNOWN_ERROR"
      message = body[:message] || "알 수 없는 오류가 발생했습니다."

      Rails.logger.error "[TossPayments] Error: #{code} - #{message}"

      Result.failure(
        error_class.new(code: code, message: message, response: body)
      )
    end

    # 네트워크 에러 처리
    def handle_network_error(error)
      Rails.logger.error "[TossPayments] Network error: #{error.class} - #{error.message}"

      Result.failure(
        NetworkError.new(
          code: "NETWORK_ERROR",
          message: "네트워크 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
        )
      )
    end

    # HTTP 클라이언트 내부 클래스
    class HttpClient
      def post(url, body, headers)
        uri = URI(url)
        http = build_http(uri)

        request = Net::HTTP::Post.new(uri.request_uri)
        headers.each { |key, value| request[key] = value }
        request.body = body

        http.request(request)
      end

      def get(url, headers)
        uri = URI(url)
        http = build_http(uri)

        request = Net::HTTP::Get.new(uri.request_uri)
        headers.each { |key, value| request[key] = value }

        http.request(request)
      end

      private

      def build_http(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 10
        http.read_timeout = 30
        http
      end
    end

    # 결과 객체 (성공/실패 래핑)
    class Result
      attr_reader :data, :error

      def initialize(success:, data: nil, error: nil)
        @success = success
        @data = data
        @error = error
      end

      def self.success(data)
        new(success: true, data: data)
      end

      def self.failure(error)
        new(success: false, error: error)
      end

      def success?
        @success
      end

      def failure?
        !@success
      end
    end
  end
end
