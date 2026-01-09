# frozen_string_literal: true

require "test_helper"

class PostViewTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @post = posts(:one)  # user: one이 작성한 게시글
  end

  test "valid post_view" do
    post_view = PostView.new(user: @other_user, post: @post)
    assert post_view.valid?
  end

  test "requires user" do
    post_view = PostView.new(user: nil, post: @post)
    assert_not post_view.valid?
    assert_includes post_view.errors[:user], "must exist"
  end

  test "requires post" do
    post_view = PostView.new(user: @other_user, post: nil)
    assert_not post_view.valid?
    assert_includes post_view.errors[:post], "must exist"
  end

  test "user can only view a post once (uniqueness)" do
    # 첫 번째 조회 생성
    PostView.create!(user: @other_user, post: @post)

    # 같은 조합으로 두 번째 조회 시도
    duplicate = PostView.new(user: @other_user, post: @post)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "counter_cache increments views_count on creation" do
    # 새 게시글 생성 (views_count = 0)
    new_post = Post.create!(
      user: @user,
      title: "Counter Cache Test",
      content: "Testing counter cache functionality",
      status: :published,
      category: :free
    )

    initial_count = new_post.views_count

    # PostView 생성
    PostView.create!(user: @other_user, post: new_post)

    # views_count가 증가했는지 확인
    new_post.reload
    assert_equal initial_count + 1, new_post.views_count
  end
end
