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
