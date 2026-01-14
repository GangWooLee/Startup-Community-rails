# frozen_string_literal: true

# API v1 게시글 컨트롤러
# 용도: n8n 자동화 연동 (게시글 조회/생성)
# 기능: 게시글 목록 조회, 게시글 생성 + 이미지 URL 첨부
module Api
  module V1
    class PostsController < BaseController
      include Rails.application.routes.url_helpers

      # GET /api/v1/posts
      # @param [Integer] page 페이지 번호 (기본값: 1)
      # @param [Integer] per_page 페이지당 개수 (기본값: 20, 최대: 100)
      # @param [String] category 카테고리 필터: free, question, promotion (선택)
      # @param [Integer] author_id 작성자 ID 필터 (선택)
      def index
        @posts = Post.published
                     .includes(:user)
                     .order(created_at: :desc)

        # 카테고리 필터 (선택)
        @posts = @posts.where(category: params[:category]) if params[:category].present?

        # 작성자 필터 (선택)
        @posts = @posts.where(user_id: params[:author_id]) if params[:author_id].present?

        # 페이지네이션
        page = [ params.fetch(:page, 1).to_i, 1 ].max
        per_page = [ [ params.fetch(:per_page, 20).to_i, 1 ].max, 100 ].min

        @posts = @posts.offset((page - 1) * per_page).limit(per_page)

        render json: index_response(page, per_page)
      end

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

      def index_response(page, per_page)
        {
          success: true,
          posts: @posts.map { |post| post_summary(post) },
          pagination: {
            page: page,
            per_page: per_page,
            total_count: Post.published.count
          }
        }
      end

      def post_summary(post)
        {
          id: post.id,
          title: post.title,
          content: post.content.truncate(200),
          category: post.category,
          author: {
            id: post.user.id,
            name: post.user.display_name
          },
          comments_count: post.comments_count,
          likes_count: post.likes_count,
          views_count: post.views_count,
          url: post_url(post, host: default_url_host),
          created_at: post.created_at.iso8601
        }
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
