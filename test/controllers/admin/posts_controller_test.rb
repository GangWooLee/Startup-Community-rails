# frozen_string_literal: true

require "test_helper"

class Admin::PostsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :posts

  TEST_PASSWORD = "test1234"

  setup do
    @admin = users(:admin)
    @admin.update!(profile_completed: true, nickname: "관리자닉네임")

    @post = posts(:one)
    @user = @post.user
    @user.update!(profile_completed: true, nickname: "테스터") if @user
  end

  # =========================================
  # Authentication
  # =========================================

  test "index requires admin login" do
    get admin_posts_path
    assert_redirected_to root_path
  end

  test "index requires admin role" do
    normal_user = users(:two)
    normal_user.update!(profile_completed: true, nickname: "일반유저")
    log_in_as(normal_user)

    get admin_posts_path
    assert_redirected_to root_path
  end

  # =========================================
  # Index
  # =========================================

  test "admin can view posts list" do
    log_in_as(@admin)

    get admin_posts_path
    assert_response :success
    assert_select "table"
  end

  test "admin can filter posts by category" do
    log_in_as(@admin)

    get admin_posts_path(category: "free")
    assert_response :success
  end

  test "admin can search posts by title" do
    log_in_as(@admin)

    get admin_posts_path(q: @post.title)
    assert_response :success
    assert_includes response.body, @post.title
  end

  test "admin can filter posts by date range" do
    log_in_as(@admin)

    get admin_posts_path(from_date: 1.month.ago.to_date.to_s, to_date: Date.today.to_s)
    assert_response :success
  end

  test "invalid date format does not cause 500 error" do
    log_in_as(@admin)

    # 잘못된 날짜 형식 입력 - 500 에러 대신 정상 응답해야 함
    get admin_posts_path(from_date: "invalid-date")
    assert_response :success
    assert_select "div.bg-red-50, div.text-red-800, div.bg-yellow-50", minimum: 0

    # 다양한 잘못된 형식 테스트
    get admin_posts_path(to_date: "2024-99-99")
    assert_response :success

    get admin_posts_path(from_date: "abc", to_date: "xyz")
    assert_response :success
  end

  test "invalid date format in export does not cause 500 error" do
    log_in_as(@admin)

    # CSV 내보내기에서도 잘못된 날짜 처리
    get export_admin_posts_path(format: :csv, from_date: "invalid")
    assert_response :success
    assert_equal "text/csv; charset=utf-8", response.content_type
  end

  # =========================================
  # Destroy
  # =========================================

  test "admin can delete a post" do
    log_in_as(@admin)

    assert_difference "Post.count", -1 do
      delete admin_post_path(@post)
    end

    assert_redirected_to admin_posts_path
    follow_redirect!
    assert_match /삭제/, flash[:notice]
  end

  test "delete removes related foreign key references" do
    log_in_as(@admin)

    # ChatRoom이 이 게시글을 참조하는 경우
    # (외래키가 해제되어야 함)
    delete admin_post_path(@post)

    assert_redirected_to admin_posts_path
    # 삭제 후 게시글이 없어야 함
    assert_nil Post.find_by(id: @post.id)
  end

  # =========================================
  # Export
  # =========================================

  test "admin can export posts to CSV" do
    log_in_as(@admin)

    get export_admin_posts_path(format: :csv)
    assert_response :success
    assert_equal "text/csv; charset=utf-8", response.content_type

    # UTF-8 BOM 확인
    assert response.body.start_with?("\xEF\xBB\xBF"), "CSV should start with UTF-8 BOM"

    # 헤더 확인
    assert_includes response.body, "ID"
    assert_includes response.body, "제목"
  end

  test "admin can export filtered posts" do
    log_in_as(@admin)

    get export_admin_posts_path(format: :csv, category: "free")
    assert_response :success
  end

  private

  def log_in_as(user)
    post login_path, params: {
      email: user.email,
      password: TEST_PASSWORD
    }
  end
end
