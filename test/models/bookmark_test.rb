# frozen_string_literal: true

require "test_helper"

class BookmarkTest < ActiveSupport::TestCase
  # =========================================
  # Fixtures & Setup
  # =========================================

  def setup
    @user = users(:one)
    @other_user = users(:two)
    @third_user = users(:three)
    @post = posts(:one)
    @post_bookmark = bookmarks(:post_bookmark_one)
  end

  # =========================================
  # Validations
  # =========================================

  test "should be valid with valid attributes" do
    # 아직 스크랩하지 않은 게시글 사용
    other_post = posts(:hiring_post)
    bookmark = Bookmark.new(user: @other_user, bookmarkable: other_post)
    assert bookmark.valid?
  end

  test "should require user" do
    bookmark = Bookmark.new(bookmarkable: @post)
    assert_not bookmark.valid?
    assert_validation_error bookmark, :user
  end

  test "should require bookmarkable" do
    bookmark = Bookmark.new(user: @user)
    assert_not bookmark.valid?
    assert_validation_error bookmark, :bookmarkable
  end

  test "should validate bookmarkable_type inclusion" do
    bookmark = Bookmark.new(user: @user)
    bookmark.bookmarkable_type = "Comment"  # Comment는 VALID_BOOKMARKABLE_TYPES에 없음
    bookmark.bookmarkable_id = comments(:one).id
    assert_not bookmark.valid?
    assert_validation_error bookmark, :bookmarkable_type
  end

  test "should allow Post as bookmarkable_type" do
    new_post = Post.create!(
      user: @other_user,
      title: "테스트",
      content: "내용",
      category: :free,
      status: :published
    )
    bookmark = Bookmark.new(user: @user, bookmarkable: new_post)
    assert bookmark.valid?
  end

  test "should prevent duplicate bookmarks" do
    # @other_user가 이미 @post를 스크랩 (post_bookmark_one fixture)
    duplicate_bookmark = Bookmark.new(user: @other_user, bookmarkable: @post)
    assert_not duplicate_bookmark.valid?
    assert_validation_error duplicate_bookmark, :user_id
  end

  # =========================================
  # Associations
  # =========================================

  test "should belong to user" do
    assert_respond_to @post_bookmark, :user
    assert_kind_of User, @post_bookmark.user
  end

  test "should belong to bookmarkable polymorphic" do
    assert_respond_to @post_bookmark, :bookmarkable
    assert_kind_of Post, @post_bookmark.bookmarkable
  end

  # =========================================
  # Scopes
  # =========================================

  test "recent scope should order by created_at desc" do
    recent_bookmarks = Bookmark.recent
    if recent_bookmarks.size > 1
      recent_bookmarks.each_cons(2) do |a, b|
        assert a.created_at >= b.created_at
      end
    end
  end

  # =========================================
  # CRUD Operations
  # =========================================

  test "should create bookmark" do
    new_post = Post.create!(
      user: @other_user,
      title: "새 글",
      content: "내용",
      category: :free,
      status: :published
    )

    assert_difference "Bookmark.count", 1 do
      Bookmark.create!(user: @user, bookmarkable: new_post)
    end
  end

  test "should destroy bookmark" do
    new_post = Post.create!(
      user: @other_user,
      title: "새 글",
      content: "내용",
      category: :free,
      status: :published
    )
    bookmark = Bookmark.create!(user: @user, bookmarkable: new_post)

    assert_difference "Bookmark.count", -1 do
      bookmark.destroy
    end
  end

  # =========================================
  # User's Bookmarks
  # =========================================

  test "user should have many bookmarks" do
    assert_respond_to @other_user, :bookmarks
  end

  test "user can bookmark multiple posts" do
    # 새 사용자 생성 (기존 fixture와 충돌 방지)
    new_user = User.create!(email: "bookmark_test@test.com", password: "test1234", name: "Test")

    post1 = Post.create!(user: @user, title: "글1", content: "내용", category: :free, status: :published)
    post2 = Post.create!(user: @user, title: "글2", content: "내용", category: :free, status: :published)

    Bookmark.create!(user: new_user, bookmarkable: post1)
    Bookmark.create!(user: new_user, bookmarkable: post2)

    assert_equal 2, new_user.bookmarks.where(bookmarkable_type: "Post").count
    new_user.destroy
  end

  # =========================================
  # Constants
  # =========================================

  test "should have VALID_BOOKMARKABLE_TYPES constant" do
    assert_includes Bookmark::VALID_BOOKMARKABLE_TYPES, "Post"
  end

  test "should only allow Post as bookmarkable" do
    # Comment는 bookmarkable이 아님
    assert_not_includes Bookmark::VALID_BOOKMARKABLE_TYPES, "Comment"
  end
end
