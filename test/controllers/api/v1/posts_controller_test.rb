# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class PostsControllerTest < ActionDispatch::IntegrationTest
      fixtures :users

      setup do
        @user = users(:one)
        @token = @user.generate_api_token!
        @valid_headers = {
          "Authorization" => "Bearer #{@token}",
          "Content-Type" => "application/json"
        }
      end

      # ===== Authentication Tests =====

      test "should return 401 without authorization header" do
        post api_v1_posts_url,
             params: { post: valid_post_params }.to_json,
             headers: { "Content-Type" => "application/json" }

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_equal "Unauthorized", json["error"]
      end

      test "should return 401 with invalid token" do
        post api_v1_posts_url,
             params: { post: valid_post_params }.to_json,
             headers: {
               "Authorization" => "Bearer invalid_token",
               "Content-Type" => "application/json"
             }

        assert_response :unauthorized
      end

      test "should return 401 with empty bearer token" do
        post api_v1_posts_url,
             params: { post: valid_post_params }.to_json,
             headers: {
               "Authorization" => "Bearer ",
               "Content-Type" => "application/json"
             }

        assert_response :unauthorized
      end

      # ===== Successful Creation Tests =====

      test "should create post with valid params" do
        assert_difference "Post.count", 1 do
          post api_v1_posts_url,
               params: { post: valid_post_params }.to_json,
               headers: @valid_headers
        end

        assert_response :created
        json = JSON.parse(response.body)

        assert json["success"]
        assert_not_nil json["post"]["id"]
        assert_equal "API 테스트 게시글", json["post"]["title"]
        assert_equal "free", json["post"]["category"]
        assert_includes json["post"]["url"], "/posts/#{json['post']['id']}"
      end

      test "should create post with question category" do
        params = valid_post_params.merge(category: "question")

        assert_difference "Post.count", 1 do
          post api_v1_posts_url,
               params: { post: params }.to_json,
               headers: @valid_headers
        end

        assert_response :created
        json = JSON.parse(response.body)
        assert_equal "question", json["post"]["category"]
      end

      test "should create post with promotion category" do
        params = valid_post_params.merge(category: "promotion")

        assert_difference "Post.count", 1 do
          post api_v1_posts_url,
               params: { post: params }.to_json,
               headers: @valid_headers
        end

        assert_response :created
        json = JSON.parse(response.body)
        assert_equal "promotion", json["post"]["category"]
      end

      test "created post should be published" do
        post api_v1_posts_url,
             params: { post: valid_post_params }.to_json,
             headers: @valid_headers

        assert_response :created
        json = JSON.parse(response.body)

        created_post = Post.find(json["post"]["id"])
        assert created_post.published?
      end

      test "created post should belong to authenticated user" do
        post api_v1_posts_url,
             params: { post: valid_post_params }.to_json,
             headers: @valid_headers

        assert_response :created
        json = JSON.parse(response.body)

        created_post = Post.find(json["post"]["id"])
        assert_equal @user.id, created_post.user_id
      end

      # ===== Validation Error Tests =====

      test "should return 422 without title" do
        params = valid_post_params.except(:title)

        assert_no_difference "Post.count" do
          post api_v1_posts_url,
               params: { post: params }.to_json,
               headers: @valid_headers
        end

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert_not json["success"]
        assert_includes json["errors"].join, "Title"
      end

      test "should return 422 without content" do
        params = valid_post_params.except(:content)

        assert_no_difference "Post.count" do
          post api_v1_posts_url,
               params: { post: params }.to_json,
               headers: @valid_headers
        end

        assert_response :unprocessable_entity
      end

      test "should create post with default category when not specified" do
        # Post 모델의 category enum에 default: :free 설정됨
        params = valid_post_params.except(:category)

        assert_difference "Post.count", 1 do
          post api_v1_posts_url,
               params: { post: params }.to_json,
               headers: @valid_headers
        end

        assert_response :created
        json = JSON.parse(response.body)
        assert_equal "free", json["post"]["category"]
      end

      test "should return 422 with invalid category" do
        params = valid_post_params.merge(category: "invalid")

        assert_no_difference "Post.count" do
          post api_v1_posts_url,
               params: { post: params }.to_json,
               headers: @valid_headers
        end

        assert_response :unprocessable_entity
      end

      # ===== Image URL Tests =====

      test "should create post with empty image_urls" do
        params = valid_post_params.merge(image_urls: [])

        assert_difference "Post.count", 1 do
          post api_v1_posts_url,
               params: { post: params }.to_json,
               headers: @valid_headers
        end

        assert_response :created
        json = JSON.parse(response.body)
        assert_equal 0, json["post"]["images_count"]
      end

      test "should ignore invalid image urls and still create post" do
        params = valid_post_params.merge(image_urls: [ "not-a-valid-url" ])

        assert_difference "Post.count", 1 do
          post api_v1_posts_url,
               params: { post: params }.to_json,
               headers: @valid_headers
        end

        assert_response :created
        json = JSON.parse(response.body)
        assert_equal 0, json["post"]["images_count"]
      end

      # NOTE: 이미지 URL 다운로드 테스트는 WebMock stub이 필요
      # 프로덕션에서 curl로 수동 테스트 권장
      # 테스트 환경에서는 HTTP 요청이 차단됨

      # ===== Response Format Tests =====

      test "success response should have correct format" do
        post api_v1_posts_url,
             params: { post: valid_post_params }.to_json,
             headers: @valid_headers

        assert_response :created
        json = JSON.parse(response.body)

        assert json.key?("success")
        assert json.key?("post")
        assert json["post"].key?("id")
        assert json["post"].key?("title")
        assert json["post"].key?("category")
        assert json["post"].key?("url")
        assert json["post"].key?("images_count")
        assert json["post"].key?("created_at")
      end

      test "error response should have correct format" do
        params = valid_post_params.except(:title)

        post api_v1_posts_url,
             params: { post: params }.to_json,
             headers: @valid_headers

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert json.key?("success")
        assert_not json["success"]
        assert json.key?("errors")
        assert json["errors"].is_a?(Array)
      end

      # ===== Index (GET) Tests =====

      test "index should return 401 without authorization" do
        get api_v1_posts_url,
            headers: { "Content-Type" => "application/json" }

        assert_response :unauthorized
      end

      test "index should return posts list" do
        # 테스트용 게시글 생성
        3.times do |i|
          Post.create!(
            user: @user,
            title: "테스트 게시글 #{i}",
            content: "내용 #{i}",
            category: :free,
            status: :published
          )
        end

        get api_v1_posts_url,
            headers: @valid_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert json["success"]
        assert json["posts"].is_a?(Array)
        assert json["pagination"].present?
      end

      test "index should filter by category" do
        Post.create!(user: @user, title: "자유", content: "내용", category: :free, status: :published)
        Post.create!(user: @user, title: "질문", content: "내용", category: :question, status: :published)

        get api_v1_posts_url,
            params: { category: "question" },
            headers: @valid_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert json["posts"].all? { |p| p["category"] == "question" }
      end

      test "index should paginate results" do
        get api_v1_posts_url,
            params: { page: 1, per_page: 5 },
            headers: @valid_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal 1, json["pagination"]["page"]
        assert_equal 5, json["pagination"]["per_page"]
        assert json["posts"].length <= 5
      end

      test "index should not return draft posts" do
        Post.create!(user: @user, title: "공개", content: "내용", status: :published)
        Post.create!(user: @user, title: "임시저장", content: "내용", status: :draft)

        get api_v1_posts_url,
            headers: @valid_headers

        assert_response :success
        json = JSON.parse(response.body)

        titles = json["posts"].map { |p| p["title"] }
        assert_includes titles, "공개"
        assert_not_includes titles, "임시저장"
      end

      test "index response should have correct format" do
        Post.create!(user: @user, title: "테스트", content: "내용", status: :published)

        get api_v1_posts_url,
            headers: @valid_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert json.key?("success")
        assert json.key?("posts")
        assert json.key?("pagination")

        if json["posts"].any?
          post_data = json["posts"].first
          assert post_data.key?("id")
          assert post_data.key?("title")
          assert post_data.key?("content")
          assert post_data.key?("category")
          assert post_data.key?("author")
          assert post_data.key?("url")
          assert post_data.key?("created_at")
        end
      end

      test "index should filter by author_id" do
        other_user = users(:two)
        Post.create!(user: @user, title: "내 글", content: "내용", status: :published)
        Post.create!(user: other_user, title: "다른 사람 글", content: "내용", status: :published)

        get api_v1_posts_url,
            params: { author_id: @user.id },
            headers: @valid_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert json["posts"].present?
        assert json["posts"].all? { |p| p["author"]["id"] == @user.id }
      end

      private

      def valid_post_params
        {
          title: "API 테스트 게시글",
          content: "이것은 API를 통해 생성된 테스트 게시글입니다.",
          category: "free"
        }
      end
    end
  end
end
