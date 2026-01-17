# frozen_string_literal: true

require "test_helper"

class BookmarkableTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @post = posts(:one)
  end

  # =========================================
  # bookmarked_by? 메서드 테스트
  # =========================================

  test "bookmarked_by? returns false when user is nil" do
    assert_not @post.bookmarked_by?(nil)
  end

  test "bookmarked_by? returns false when user has not bookmarked" do
    @post.bookmarks.where(user: @user).destroy_all

    assert_not @post.bookmarked_by?(@user)
  end

  test "bookmarked_by? returns true when user has bookmarked" do
    @post.bookmarks.find_or_create_by!(user: @user)

    assert @post.bookmarked_by?(@user)
  end

  # =========================================
  # toggle_bookmark! 메서드 테스트
  # =========================================

  test "toggle_bookmark! returns nil when user is nil" do
    result = @post.toggle_bookmark!(nil)

    assert_nil result
  end

  test "toggle_bookmark! adds bookmark when not bookmarked" do
    @post.bookmarks.where(user: @user).destroy_all
    initial_count = @post.bookmarks.count

    result = @post.toggle_bookmark!(@user)

    assert_equal true, result
    assert_equal initial_count + 1, @post.bookmarks.count
    assert @post.bookmarked_by?(@user)
  end

  test "toggle_bookmark! removes bookmark when already bookmarked" do
    @post.bookmarks.find_or_create_by!(user: @user)
    initial_count = @post.bookmarks.count

    result = @post.toggle_bookmark!(@user)

    assert_equal false, result
    assert_equal initial_count - 1, @post.bookmarks.count
    assert_not @post.bookmarked_by?(@user)
  end

  # =========================================
  # bookmarks_count 메서드 테스트
  # =========================================

  test "bookmarks_count returns zero when no bookmarks" do
    @post.bookmarks.destroy_all

    assert_equal 0, @post.bookmarks_count
  end

  test "bookmarks_count returns correct count" do
    @post.bookmarks.destroy_all
    @post.bookmarks.create!(user: @user)
    @post.bookmarks.create!(user: @other_user)

    assert_equal 2, @post.bookmarks_count
  end

  # =========================================
  # bookmarks association 테스트
  # =========================================

  test "post has many bookmarks" do
    assert_respond_to @post, :bookmarks
  end

  test "destroying post destroys associated bookmarks" do
    @post.bookmarks.find_or_create_by!(user: @user)
    bookmark_id = @post.bookmarks.last.id

    @post.destroy

    assert_nil Bookmark.find_by(id: bookmark_id)
  end
end
