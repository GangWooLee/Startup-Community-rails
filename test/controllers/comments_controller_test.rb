# frozen_string_literal: true

require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @third_user = users(:three)
    @post = posts(:one)
    @comment = comments(:one) # belongs to @other_user
    @user_comment = comments(:reply_to_one) # belongs to @user
    @comment_two = comments(:two) # belongs to @third_user
  end

  # =========================================
  # Authentication Tests
  # =========================================

  test "should redirect to login when not authenticated (HTML)" do
    post post_comments_path(@post), params: { comment: { content: "Test" } }
    assert_redirected_to login_path
    assert_equal "로그인이 필요합니다.", flash[:alert]
  end

  test "should return unauthorized when not authenticated (JSON)" do
    post post_comments_path(@post), params: { comment: { content: "Test" } }, as: :json
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal "로그인이 필요합니다.", json_response["error"]
  end

  test "should not create comment when not authenticated" do
    assert_no_difference("Comment.count") do
      post post_comments_path(@post), params: { comment: { content: "Test" } }
    end
  end

  # =========================================
  # Create Action Tests
  # =========================================

  test "should create comment" do
    log_in_as(@user)

    assert_difference("Comment.count", 1) do
      post post_comments_path(@post), params: { comment: { content: "새 댓글입니다!" } }
    end

    comment = Comment.last
    assert_equal "새 댓글입니다!", comment.content
    assert_equal @user, comment.user
    assert_equal @post, comment.post
  end

  test "should create comment via turbo_stream" do
    log_in_as(@user)

    post post_comments_path(@post),
         params: { comment: { content: "Turbo 댓글" } },
         as: :turbo_stream

    assert_response :success
    assert_match(/turbo-stream/, response.content_type)
    assert_match(/comments-list/, response.body)
  end

  test "should create comment via HTML" do
    log_in_as(@user)

    post post_comments_path(@post), params: { comment: { content: "HTML 댓글" } }

    assert_response :redirect
    assert_redirected_to post_path(@post)
    assert_equal "댓글이 작성되었습니다.", flash[:notice]
  end

  test "should create comment via JSON" do
    log_in_as(@user)

    post post_comments_path(@post),
         params: { comment: { content: "JSON 댓글" } },
         as: :json

    assert_response :created

    json_response = JSON.parse(response.body)
    assert_equal "JSON 댓글", json_response["content"]
    assert_not_nil json_response["id"]
    assert_not_nil json_response["user"]
    assert json_response["is_owner"]
  end

  test "should create reply to existing comment" do
    log_in_as(@user)

    assert_difference("Comment.count", 1) do
      post post_comments_path(@post),
           params: { comment: { content: "대댓글입니다", parent_id: @comment.id } }
    end

    reply = Comment.last
    assert_equal @comment, reply.parent
    assert reply.reply?
  end

  test "should create reply via turbo_stream" do
    log_in_as(@user)

    post post_comments_path(@post),
         params: { comment: { content: "대댓글", parent_id: @comment.id } },
         as: :turbo_stream

    assert_response :success
    assert_match(/replies-#{@comment.id}/, response.body)
  end

  test "should not create empty comment" do
    log_in_as(@user)

    assert_no_difference("Comment.count") do
      post post_comments_path(@post), params: { comment: { content: "" } }
    end
  end

  test "should return error for invalid comment via JSON" do
    log_in_as(@user)

    post post_comments_path(@post),
         params: { comment: { content: "" } },
         as: :json

    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert json_response["errors"].present?
  end

  test "should update comments count after create" do
    log_in_as(@user)

    initial_count = @post.comments_count

    post post_comments_path(@post), params: { comment: { content: "카운트 테스트" } }

    @post.reload
    assert_equal initial_count + 1, @post.comments_count
  end

  # =========================================
  # Destroy Action Tests
  # =========================================

  test "should destroy own comment" do
    log_in_as(@user)

    assert_difference("Comment.count", -1) do
      delete post_comment_path(@post, @user_comment)
    end
  end

  test "should redirect after destroying via HTML" do
    log_in_as(@user)

    delete post_comment_path(@post, @user_comment)

    assert_redirected_to post_path(@post)
    assert_equal "댓글이 삭제되었습니다.", flash[:notice]
  end

  test "should destroy via turbo_stream" do
    log_in_as(@user)

    delete post_comment_path(@post, @user_comment), as: :turbo_stream

    assert_response :success
    assert_match(/turbo-stream/, response.content_type)
    assert_match(/comment-#{@user_comment.id}/, response.body)
    assert_match(/remove/, response.body)
  end

  test "should destroy via JSON" do
    log_in_as(@user)

    delete post_comment_path(@post, @user_comment), as: :json

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_not_nil json_response["comments_count"]
  end

  test "should not destroy other users comment" do
    log_in_as(@user)

    assert_no_difference("Comment.count") do
      delete post_comment_path(@post, @comment) # belongs to other_user
    end

    assert_response :redirect
    assert_equal "권한이 없습니다.", flash[:alert]
  end

  test "should return forbidden when destroying other users comment via JSON" do
    log_in_as(@user)

    delete post_comment_path(@post, @comment), as: :json

    assert_response :forbidden

    json_response = JSON.parse(response.body)
    assert_equal "권한이 없습니다.", json_response["error"]
  end

  test "should update comments count after destroy" do
    log_in_as(@user)

    initial_count = @post.comments_count

    delete post_comment_path(@post, @user_comment)

    @post.reload
    assert_equal initial_count - 1, @post.comments_count
  end

  # =========================================
  # Like Action Tests
  # =========================================

  test "should toggle like on comment" do
    log_in_as(@user)

    # First call: like
    post like_post_comment_path(@post, @comment), as: :json
    assert @comment.reload.liked_by?(@user)

    # Second call: unlike
    post like_post_comment_path(@post, @comment), as: :json
    assert_not @comment.reload.liked_by?(@user)
  end

  test "should respond with turbo_stream when liking comment" do
    log_in_as(@user)

    post like_post_comment_path(@post, @comment), as: :turbo_stream

    assert_response :success
    assert_match(/turbo-stream/, response.content_type)
    assert_match(/comment-like-button-#{@comment.id}/, response.body)
  end

  test "should respond with JSON when liking comment" do
    log_in_as(@user)

    post like_post_comment_path(@post, @comment), as: :json

    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response.key?("liked")
    assert json_response.key?("likes_count")
  end

  test "should redirect when liking via HTML" do
    log_in_as(@user)

    post like_post_comment_path(@post, @comment)

    assert_response :redirect
  end

  # =========================================
  # Edge Cases (rescue_from handles RecordNotFound in non-dev environments)
  # =========================================

  test "should return 404 for non-existent post" do
    log_in_as(@user)
    non_existent_post = Post.new(id: 999999)

    post post_comments_path(non_existent_post), params: { comment: { content: "Test" } }
    assert_response :not_found
  end

  test "should return 404 for non-existent comment on destroy" do
    log_in_as(@user)
    non_existent_comment = Comment.new(id: 999999)

    delete post_comment_path(@post, non_existent_comment)
    assert_response :not_found
  end

  test "should return 404 for non-existent comment on like" do
    log_in_as(@user)
    non_existent_comment = Comment.new(id: 999999)

    post like_post_comment_path(@post, non_existent_comment)
    assert_response :not_found
  end

  # =========================================
  # JSON Response Structure Tests
  # =========================================

  test "json response for create contains all required fields" do
    log_in_as(@user)

    post post_comments_path(@post),
         params: { comment: { content: "구조 테스트" } },
         as: :json

    json_response = JSON.parse(response.body)

    assert json_response.key?("id")
    assert json_response.key?("content")
    assert json_response.key?("user")
    assert json_response["user"].key?("id")
    assert json_response["user"].key?("name")
    assert json_response.key?("parent_id")
    assert json_response.key?("likes_count")
    assert json_response.key?("liked")
    assert json_response.key?("replies_count")
    assert json_response.key?("created_at")
    assert json_response.key?("is_owner")
  end

  # =========================================
  # Turbo Stream Response Structure Tests
  # =========================================

  test "turbo_stream response for create updates comments count" do
    log_in_as(@user)

    post post_comments_path(@post),
         params: { comment: { content: "카운트 업데이트 테스트" } },
         as: :turbo_stream

    assert_response :success
    assert_match(/comments-count/, response.body)
    assert_match(/update/, response.body)
  end

  test "turbo_stream response for destroy removes comment and updates count" do
    log_in_as(@user)

    delete post_comment_path(@post, @user_comment), as: :turbo_stream

    assert_match(/remove/, response.body)
    assert_match(/comments-count/, response.body)
  end
end
