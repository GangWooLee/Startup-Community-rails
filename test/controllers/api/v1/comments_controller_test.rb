# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class CommentsControllerTest < ActionDispatch::IntegrationTest
      fixtures :users, :posts, :comments

      setup do
        @user = users(:one)
        @post = posts(:one)  # published 상태
        @draft_post = posts(:draft_post)  # draft 상태
        @token = @user.generate_api_token!
        @valid_headers = {
          "Authorization" => "Bearer #{@token}",
          "Content-Type" => "application/json"
        }
      end

      # ===== Authentication Tests =====

      test "should return 401 without authorization header" do
        post api_v1_post_comments_url(@post),
             params: { comment: valid_comment_params }.to_json,
             headers: { "Content-Type" => "application/json" }

        assert_response :unauthorized
        json = JSON.parse(response.body)
        assert_equal "Unauthorized", json["error"]
      end

      test "should return 401 with invalid token" do
        post api_v1_post_comments_url(@post),
             params: { comment: valid_comment_params }.to_json,
             headers: {
               "Authorization" => "Bearer invalid_token",
               "Content-Type" => "application/json"
             }

        assert_response :unauthorized
      end

      test "should return 401 with empty bearer token" do
        post api_v1_post_comments_url(@post),
             params: { comment: valid_comment_params }.to_json,
             headers: {
               "Authorization" => "Bearer ",
               "Content-Type" => "application/json"
             }

        assert_response :unauthorized
      end

      # ===== Successful Creation Tests =====

      test "should create comment with valid params" do
        assert_difference "Comment.count", 1 do
          post api_v1_post_comments_url(@post),
               params: { comment: valid_comment_params }.to_json,
               headers: @valid_headers
        end

        assert_response :created
        json = JSON.parse(response.body)

        assert json["success"]
        assert_not_nil json["comment"]["id"]
        assert_equal valid_comment_params[:content], json["comment"]["content"]
        assert_equal @post.id, json["comment"]["post_id"]
      end

      test "created comment should belong to authenticated user" do
        post api_v1_post_comments_url(@post),
             params: { comment: valid_comment_params }.to_json,
             headers: @valid_headers

        assert_response :created
        json = JSON.parse(response.body)

        created_comment = Comment.find(json["comment"]["id"])
        assert_equal @user.id, created_comment.user_id
      end

      test "created comment should belong to correct post" do
        post api_v1_post_comments_url(@post),
             params: { comment: valid_comment_params }.to_json,
             headers: @valid_headers

        assert_response :created
        json = JSON.parse(response.body)

        created_comment = Comment.find(json["comment"]["id"])
        assert_equal @post.id, created_comment.post_id
      end

      # ===== Validation Error Tests =====

      test "should return 422 without content" do
        assert_no_difference "Comment.count" do
          post api_v1_post_comments_url(@post),
               params: { comment: { content: nil } }.to_json,
               headers: @valid_headers
        end

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert_not json["success"]
        assert json["errors"].is_a?(Array)
      end

      test "should return 422 with empty content" do
        assert_no_difference "Comment.count" do
          post api_v1_post_comments_url(@post),
               params: { comment: { content: "" } }.to_json,
               headers: @valid_headers
        end

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert_not json["success"]
      end

      test "should return 422 with content exceeding 1000 chars" do
        long_content = "a" * 1001

        assert_no_difference "Comment.count" do
          post api_v1_post_comments_url(@post),
               params: { comment: { content: long_content } }.to_json,
               headers: @valid_headers
        end

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert_not json["success"]
        assert json["errors"].is_a?(Array)
      end

      # ===== Edge Case Tests =====

      test "should return 404 when post not found" do
        post api_v1_post_comments_url(post_id: 99999),
             params: { comment: valid_comment_params }.to_json,
             headers: @valid_headers

        assert_response :not_found
        json = JSON.parse(response.body)
        assert_equal "Not Found", json["error"]
      end

      test "should return 404 when post is draft" do
        post api_v1_post_comments_url(@draft_post),
             params: { comment: valid_comment_params }.to_json,
             headers: @valid_headers

        assert_response :not_found
        json = JSON.parse(response.body)
        assert_equal "Not Found", json["error"]
      end

      # ===== Response Format Tests =====

      test "success response should have correct format" do
        post api_v1_post_comments_url(@post),
             params: { comment: valid_comment_params }.to_json,
             headers: @valid_headers

        assert_response :created
        json = JSON.parse(response.body)

        assert json.key?("success")
        assert json.key?("comment")
        assert json["comment"].key?("id")
        assert json["comment"].key?("content")
        assert json["comment"].key?("post_id")
        assert json["comment"].key?("user_id")
        assert json["comment"].key?("created_at")
      end

      test "error response should have correct format" do
        post api_v1_post_comments_url(@post),
             params: { comment: { content: "" } }.to_json,
             headers: @valid_headers

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert json.key?("success")
        assert_not json["success"]
        assert json.key?("errors")
        assert json["errors"].is_a?(Array)
      end

      private

      def valid_comment_params
        { content: "API 테스트 댓글입니다." }
      end
    end
  end
end
