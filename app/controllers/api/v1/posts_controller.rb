# frozen_string_literal: true

# API v1 게시글 컨트롤러
# 용도: n8n 자동 게시글 생성 (커뮤니티 초기 활성화용)
# 기능: 게시글 생성 + 이미지 URL 첨부
module Api
  module V1
    class PostsController < BaseController
      include Rails.application.routes.url_helpers

      # POST /api/v1/posts
      # @param [Hash] post 게시글 파라미터
      # @option post [String] title 제목 (필수)
      # @option post [String] content 내용 (필수)
      # @option post [String] category 카테고리: free, question, promotion (필수)
      # @option post [Array<String>] image_urls 이미지 URL 배열 (선택, 최대 5개)
      def create
        @post = current_api_user.posts.build(post_params)
        @post.status = :published

        # 이미지 URL 처리 (있는 경우)
        attach_images_from_urls if image_urls.present?

        if @post.save
          render json: success_response, status: :created
        else
          render json: error_response, status: :unprocessable_entity
        end
      rescue ArgumentError => e
        # 잘못된 enum 값 (category 등)
        Rails.logger.warn "[API] Invalid enum value: #{e.message}"
        render json: {
          success: false,
          errors: [ e.message ]
        }, status: :unprocessable_entity
      rescue StandardError => e
        Rails.logger.error "[API] Post creation failed: #{e.message}"
        render json: {
          success: false,
          error: "Internal Server Error",
          message: "게시글 생성 중 오류가 발생했습니다"
        }, status: :internal_server_error
      end

      private

      def post_params
        params.require(:post).permit(:title, :content, :category)
      end

      def image_urls
        @image_urls ||= Array(params.dig(:post, :image_urls)).first(5)
      end

      def success_response
        {
          success: true,
          post: {
            id: @post.id,
            title: @post.title,
            category: @post.category,
            url: post_url(@post, host: default_url_host),
            images_count: @post.images.count,
            created_at: @post.created_at.iso8601
          }
        }
      end

      def error_response
        {
          success: false,
          errors: @post.errors.full_messages
        }
      end

      def default_url_host
        Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3000"
      end

      # 이미지 URL에서 이미지를 다운로드하여 첨부
      # @note 실패 시 로그만 남기고 게시글 생성은 계속 진행
      def attach_images_from_urls
        image_urls.each do |url|
          attach_image_from_url(url)
        end
      end

      def attach_image_from_url(url)
        uri = URI.parse(url)

        # HTTP/HTTPS만 허용
        unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
          Rails.logger.warn "[API] Invalid image URL scheme: #{url}"
          return
        end

        response = fetch_image(uri)
        return unless response.is_a?(Net::HTTPSuccess)

        content_type = response["content-type"]&.split(";")&.first || "image/jpeg"

        # 이미지 타입만 허용
        unless content_type.start_with?("image/")
          Rails.logger.warn "[API] Non-image content type: #{content_type}"
          return
        end

        filename = extract_filename(uri, content_type)

        @post.images.attach(
          io: StringIO.new(response.body),
          filename: filename,
          content_type: content_type
        )

        Rails.logger.info "[API] Image attached: #{filename}"
      rescue URI::InvalidURIError => e
        Rails.logger.warn "[API] Invalid URI: #{url} - #{e.message}"
      rescue StandardError => e
        Rails.logger.warn "[API] Failed to download image from #{url}: #{e.message}"
      end

      def fetch_image(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == "https")
        http.open_timeout = 10
        http.read_timeout = 30

        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = "UnderwAI-Bot/1.0"

        http.request(request)
      end

      def extract_filename(uri, content_type)
        basename = File.basename(uri.path)

        if basename.present? && basename.include?(".")
          basename
        else
          extension = Rack::Mime::MIME_TYPES.invert[content_type] || ".jpg"
          "image_#{SecureRandom.hex(4)}#{extension}"
        end
      end
    end
  end
end
