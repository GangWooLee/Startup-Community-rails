# frozen_string_literal: true

require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @post = posts(:one)
    @other_post = posts(:two)  # user :two의 게시글
    @draft_post = posts(:draft_post)
    @hiring_post = posts(:hiring_post)
  end

  # ===== Index 테스트 =====

  test "should get index without login when browse param present" do
    get community_path(browse: true)
    assert_response :success
  end

  test "should get index when logged in" do
    log_in_as(@user)
    get community_path
    assert_response :success
  end

  test "should redirect to onboarding when not logged in and no browse param" do
    get community_path
    assert_redirected_to root_path
  end

  test "index shows only published community posts" do
    log_in_as(@user)
    get community_path
    assert_response :success

    # 커뮤니티 글은 표시
    assert_match @post.title, response.body

    # Draft 글은 표시 안됨
    assert_no_match @draft_post.title, response.body

    # 외주 글(hiring)은 표시 안됨
    assert_no_match @hiring_post.title, response.body
  end

  test "index can filter by category" do
    log_in_as(@user)
    get community_path(category: "question")
    assert_response :success

    # 질문 카테고리만 표시
    assert_match posts(:two).title, response.body
  end

  test "index supports pagination" do
    log_in_as(@user)
    get community_path(page: 1)
    assert_response :success
  end

  # ===== Show 테스트 =====

  test "should show post when logged in" do
    log_in_as(@user)
    get post_path(@post)
    assert_response :success
    assert_match @post.title, response.body
  end

  test "should show post when not logged in" do
    get post_path(@post)
    assert_response :success
  end

  test "show records view for logged in user" do
    log_in_as(@other_user)  # 다른 사용자로 조회
    assert_difference "@post.reload.views_count", 1 do
      get post_path(@post)
    end
    assert_response :success
  end

  test "show does not record view for own post" do
    log_in_as(@user)  # 게시글 작성자로 조회
    assert_no_difference "@post.reload.views_count" do
      get post_path(@post)
    end
  end

  # ===== New 테스트 =====

  test "should get new when logged in" do
    log_in_as(@user)
    get new_post_path
    assert_response :success
  end

  test "should redirect new when not logged in" do
    get new_post_path
    assert_redirected_to login_path
  end

  test "new sets default category based on type param" do
    log_in_as(@user)
    get new_post_path(type: "outsourcing")
    assert_response :success
    # hiring 카테고리가 기본값
  end

  # ===== Create 테스트 =====

  test "should create post when logged in" do
    log_in_as(@user)

    assert_difference "Post.count", 1 do
      post posts_path, params: {
        post: {
          title: "새로운 테스트 게시글",
          content: "테스트 게시글 내용입니다. 충분히 길게 작성합니다.",
          category: "free"
        }
      }
    end

    assert_redirected_to community_path
    assert_equal "게시글이 작성되었습니다.", flash[:notice]
  end

  test "should not create post when not logged in" do
    assert_no_difference "Post.count" do
      post posts_path, params: {
        post: {
          title: "테스트",
          content: "내용",
          category: "free"
        }
      }
    end

    assert_redirected_to login_path
  end

  test "should not create post with invalid params" do
    log_in_as(@user)

    assert_no_difference "Post.count" do
      post posts_path, params: {
        post: {
          title: "",  # 필수 필드 누락
          content: "내용",
          category: "free"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create outsourcing post redirects to job_posts_path" do
    log_in_as(@user)

    post posts_path, params: {
      post: {
        title: "개발자 구합니다",
        content: "Rails 개발자를 구합니다. 경력 3년 이상.",
        category: "hiring",
        service_type: "development",
        price: 5000000
      }
    }

    assert_redirected_to job_posts_path
  end

  # ===== Edit 테스트 =====

  test "should get edit for own post" do
    log_in_as(@user)
    get edit_post_path(@post)
    assert_response :success
  end

  test "should not get edit for others post" do
    log_in_as(@other_user)
    get edit_post_path(@post)  # user :one의 게시글
    assert_redirected_to posts_path
    assert_equal "권한이 없습니다.", flash[:alert]
  end

  test "should redirect edit when not logged in" do
    get edit_post_path(@post)
    assert_redirected_to login_path
  end

  # ===== Update 테스트 =====

  test "should update own post" do
    log_in_as(@user)

    patch post_path(@post), params: {
      post: {
        title: "수정된 제목",
        content: @post.content,
        category: @post.category
      }
    }

    assert_redirected_to post_path(@post)
    assert_equal "게시글이 수정되었습니다.", flash[:notice]

    @post.reload
    assert_equal "수정된 제목", @post.title
  end

  test "should not update others post" do
    log_in_as(@other_user)
    original_title = @post.title

    patch post_path(@post), params: {
      post: { title: "악의적 수정 시도" }
    }

    assert_redirected_to posts_path
    assert_equal "권한이 없습니다.", flash[:alert]

    @post.reload
    assert_equal original_title, @post.title
  end

  test "should not update when not logged in" do
    patch post_path(@post), params: {
      post: { title: "비로그인 수정 시도" }
    }

    assert_redirected_to login_path
  end

  test "update clears outsourcing fields for community category" do
    log_in_as(@user)

    # 먼저 hiring 글 생성
    @hiring_post.update!(user: @user)  # user :one 소유로 변경

    patch post_path(@hiring_post), params: {
      post: {
        title: @hiring_post.title,
        content: @hiring_post.content,
        category: "free",  # 커뮤니티 카테고리로 변경
        service_type: "development",  # 이 값은 무시되어야 함
        price: 1000000
      }
    }

    assert_redirected_to post_path(@hiring_post)
    @hiring_post.reload

    assert_equal "free", @hiring_post.category
    assert_nil @hiring_post.service_type  # 초기화됨
    assert_nil @hiring_post.price  # 초기화됨
  end

  # ===== Destroy 테스트 =====

  test "should destroy own post" do
    log_in_as(@user)

    assert_difference "Post.count", -1 do
      delete post_path(@post)
    end

    assert_redirected_to posts_path
    assert_equal "게시글이 삭제되었습니다.", flash[:notice]
  end

  test "should not destroy others post" do
    log_in_as(@other_user)

    assert_no_difference "Post.count" do
      delete post_path(@post)
    end

    assert_redirected_to posts_path
    assert_equal "권한이 없습니다.", flash[:alert]
  end

  test "should not destroy when not logged in" do
    assert_no_difference "Post.count" do
      delete post_path(@post)
    end

    assert_redirected_to login_path
  end

  # ===== Remove Image 테스트 =====

  test "should redirect remove_image when not logged in" do
    delete remove_image_post_path(@post, image_id: 1)
    assert_redirected_to login_path
  end

  test "should not remove image from others post" do
    log_in_as(@other_user)
    delete remove_image_post_path(@post, image_id: 999)
    assert_redirected_to posts_path
    assert_equal "권한이 없습니다.", flash[:alert]
  end

  # ===== 헬퍼 =====

  private

  def log_in_as(user)
    post login_path, params: { email: user.email, password: "test1234" }
    assert_response :redirect, "Login should succeed"
  end
end
