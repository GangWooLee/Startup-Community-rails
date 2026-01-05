# frozen_string_literal: true

require "test_helper"

class BookmarksControllerTest < ActionDispatch::IntegrationTest
  TEST_PASSWORD = "test1234"

  def setup
    @user = users(:one)
    @other_user = users(:two)
    @post = posts(:one)
    @post_with_bookmark = posts(:two)  # User three has bookmarked this
    @existing_bookmark = bookmarks(:post_bookmark_two)  # User three's bookmark on post two
  end

  # =========================================
  # Authentication Tests
  # =========================================

  test "should redirect to login when toggling bookmark without authentication (HTML)" do
    post bookmark_post_path(@post)
    assert_redirected_to login_path
    assert_equal "로그인이 필요합니다.", flash[:alert]
  end

  test "should return unauthorized JSON when toggling bookmark without authentication (JSON)" do
    post bookmark_post_path(@post), as: :json
    assert_response :unauthorized
    assert_equal "로그인이 필요합니다.", json_response["error"]
  end

  test "should redirect to login when toggling bookmark without authentication (Turbo Stream)" do
    post bookmark_post_path(@post), as: :turbo_stream
    assert_redirected_to login_path
  end

  # =========================================
  # Toggle Action - Create Bookmark Tests
  # =========================================

  test "should create bookmark when toggling unbookmarked post (HTML)" do
    log_in_as(@user)

    assert_difference("Bookmark.count", 1) do
      post bookmark_post_path(@post_with_bookmark)
    end

    assert_redirected_to post_path(@post_with_bookmark)
    assert @post_with_bookmark.bookmarked_by?(@user)
  end

  test "should create bookmark when toggling unbookmarked post (JSON)" do
    log_in_as(@user)

    assert_difference("Bookmark.count", 1) do
      post bookmark_post_path(@post_with_bookmark), as: :json
    end

    assert_response :success
    response_data = json_response
    assert response_data["bookmarked"]
    assert_equal @post_with_bookmark.bookmarks_count, response_data["bookmarks_count"]
  end

  test "should create bookmark when toggling unbookmarked post (Turbo Stream)" do
    log_in_as(@user)

    assert_difference("Bookmark.count", 1) do
      post bookmark_post_path(@post_with_bookmark), as: :turbo_stream
    end

    assert_response :success
    assert_match /turbo-stream/, response.body
    assert_match /bookmark-button-#{@post_with_bookmark.id}/, response.body
  end

  # =========================================
  # Toggle Action - Destroy Bookmark Tests
  # =========================================

  test "should destroy bookmark when toggling bookmarked post (HTML)" do
    user_three = users(:three)
    log_in_as(user_three)

    assert @post_with_bookmark.bookmarked_by?(user_three)

    assert_difference("Bookmark.count", -1) do
      post bookmark_post_path(@post_with_bookmark)
    end

    assert_redirected_to post_path(@post_with_bookmark)
    assert_not @post_with_bookmark.bookmarked_by?(user_three)
  end

  test "should destroy bookmark when toggling bookmarked post (JSON)" do
    user_three = users(:three)
    log_in_as(user_three)

    assert @post_with_bookmark.bookmarked_by?(user_three)

    assert_difference("Bookmark.count", -1) do
      post bookmark_post_path(@post_with_bookmark), as: :json
    end

    assert_response :success
    response_data = json_response
    assert_not response_data["bookmarked"]
    assert_equal @post_with_bookmark.bookmarks_count, response_data["bookmarks_count"]
  end

  test "should destroy bookmark when toggling bookmarked post (Turbo Stream)" do
    user_three = users(:three)
    log_in_as(user_three)

    assert @post_with_bookmark.bookmarked_by?(user_three)

    assert_difference("Bookmark.count", -1) do
      post bookmark_post_path(@post_with_bookmark), as: :turbo_stream
    end

    assert_response :success
    assert_match /turbo-stream/, response.body
    assert_match /bookmark-button-#{@post_with_bookmark.id}/, response.body
  end

  # =========================================
  # Toggle Multiple Times Tests
  # =========================================

  test "should toggle bookmark on and off correctly" do
    log_in_as(@user)

    # First toggle - create bookmark
    assert_difference("Bookmark.count", 1) do
      post bookmark_post_path(@post), as: :json
    end
    assert @post.bookmarked_by?(@user)

    # Second toggle - remove bookmark
    assert_difference("Bookmark.count", -1) do
      post bookmark_post_path(@post), as: :json
    end
    assert_not @post.bookmarked_by?(@user)

    # Third toggle - create bookmark again
    assert_difference("Bookmark.count", 1) do
      post bookmark_post_path(@post), as: :json
    end
    assert @post.bookmarked_by?(@user)
  end

  # =========================================
  # Edge Cases Tests
  # =========================================

  test "should return 404 for non-existent post" do
    log_in_as(@user)

    post bookmark_post_path(id: 999999)
    assert_response :not_found
  end

  test "should allow different users to bookmark same post" do
    # Use a fresh post that no one has bookmarked
    fresh_post = posts(:promotion_post)

    # User one bookmarks the post
    log_in_as(@user)
    assert_difference("Bookmark.count", 1) do
      post bookmark_post_path(fresh_post), as: :json
    end
    assert fresh_post.bookmarked_by?(@user)

    # Reset the session by making a new request
    reset!

    # User two also bookmarks the post (in a separate session)
    log_in_as(@other_user)
    assert_difference("Bookmark.count", 1) do
      post bookmark_post_path(fresh_post), as: :json
    end
    assert fresh_post.bookmarked_by?(@other_user)
  end

  # =========================================
  # Bookmarking Different Post Types Tests
  # =========================================

  test "should bookmark community post" do
    log_in_as(@user)
    community_post = posts(:one)

    assert_difference("Bookmark.count", 1) do
      post bookmark_post_path(community_post), as: :json
    end

    assert_response :success
    assert community_post.bookmarked_by?(@user)
  end

  test "should bookmark hiring post" do
    log_in_as(@other_user)
    hiring_post = posts(:hiring_post)

    assert_difference("Bookmark.count", 1) do
      post bookmark_post_path(hiring_post), as: :json
    end

    assert_response :success
    assert hiring_post.bookmarked_by?(@other_user)
  end

  test "should bookmark seeking post" do
    log_in_as(@user)
    seeking_post = posts(:seeking_post)

    assert_difference("Bookmark.count", 1) do
      post bookmark_post_path(seeking_post), as: :json
    end

    assert_response :success
    assert seeking_post.bookmarked_by?(@user)
  end

  test "should bookmark draft post" do
    log_in_as(@other_user)
    draft_post = posts(:draft_post)

    assert_difference("Bookmark.count", 1) do
      post bookmark_post_path(draft_post), as: :json
    end

    assert_response :success
    assert draft_post.bookmarked_by?(@other_user)
  end

  # =========================================
  # Response Format Tests
  # =========================================

  test "JSON response should include bookmarked status and count" do
    log_in_as(@user)

    post bookmark_post_path(@post), as: :json

    assert_response :success
    response_data = json_response

    assert response_data.key?("bookmarked")
    assert response_data.key?("bookmarks_count")
    assert_equal true, response_data["bookmarked"]
    assert_kind_of Integer, response_data["bookmarks_count"]
  end

  test "Turbo Stream response should replace bookmark button" do
    log_in_as(@user)

    post bookmark_post_path(@post), as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_match /action="replace"/, response.body
    assert_match /target="bookmark-button-#{@post.id}"/, response.body
  end

  # =========================================
  # Bookmark Count Accuracy Tests
  # =========================================

  test "bookmarks count should be accurate after multiple operations" do
    log_in_as(@user)

    initial_count = @post.bookmarks_count

    # Add bookmark
    post bookmark_post_path(@post), as: :json
    @post.reload
    assert_equal initial_count + 1, @post.bookmarks_count

    # Remove bookmark
    post bookmark_post_path(@post), as: :json
    @post.reload
    assert_equal initial_count, @post.bookmarks_count
  end
end
