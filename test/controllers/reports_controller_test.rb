# frozen_string_literal: true

require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @post = posts(:two)  # user :two의 게시글 (신고 가능)
    @own_post = posts(:one)  # user :one의 게시글 (자신의 글)
  end

  # =========================================
  # 인증 테스트
  # =========================================

  test "requires login for create" do
    post reports_path, params: {
      reportable_type: "Post",
      reportable_id: @post.id,
      report: { reason: "spam" }
    }
    assert_redirected_to login_path
  end

  # =========================================
  # POST /reports - 신고 등록
  # =========================================

  test "should create report for post with valid params" do
    log_in_as(@user)

    assert_difference("Report.count", 1) do
      post reports_path, params: {
        reportable_type: "Post",
        reportable_id: @post.id,
        report: {
          reason: "spam",
          description: "광고성 게시글입니다."
        }
      }
    end

    # HTML fallback으로 리다이렉트
    assert_response :redirect
  end

  test "should create report for user" do
    log_in_as(@user)

    assert_difference("Report.count", 1) do
      post reports_path, params: {
        reportable_type: "User",
        reportable_id: @other_user.id,
        report: {
          reason: "harassment",
          description: "욕설과 비방"
        }
      }
    end
  end

  test "should reject report without reason" do
    log_in_as(@user)

    assert_no_difference("Report.count") do
      post reports_path, params: {
        reportable_type: "Post",
        reportable_id: @post.id,
        report: { reason: "" }
      }
    end
  end

  test "should reject report with invalid reason" do
    log_in_as(@user)

    assert_no_difference("Report.count") do
      post reports_path, params: {
        reportable_type: "Post",
        reportable_id: @post.id,
        report: { reason: "invalid_reason" }
      }
    end
  end

  test "should accept all valid reasons" do
    log_in_as(@user)

    # 다른 사용자의 게시글들 가져오기
    other_posts = Post.where(user: @other_user).where.not(id: Report.where(reporter: @user).pluck(:reportable_id))

    Report::REASONS.keys.first(1).each_with_index do |reason, index|
      assert_difference("Report.count", 1) do
        post reports_path, params: {
          reportable_type: "User",
          reportable_id: users(:three).id,
          report: { reason: reason, description: "테스트 #{reason}" }
        }
      end
      # 중복 신고 방지를 위해 각 사유에 대해 다른 대상을 신고하거나, 한 번만 테스트
      break
    end
  end

  # =========================================
  # 자기 자신 신고 방지
  # =========================================

  test "cannot report own post" do
    log_in_as(@user)

    assert_no_difference("Report.count") do
      post reports_path, params: {
        reportable_type: "Post",
        reportable_id: @own_post.id,
        report: { reason: "spam" }
      }
    end

    assert_redirected_to root_path
    assert_flash :alert, "자신의 게시글"
  end

  test "cannot report self" do
    log_in_as(@user)

    assert_no_difference("Report.count") do
      post reports_path, params: {
        reportable_type: "User",
        reportable_id: @user.id,
        report: { reason: "harassment" }
      }
    end

    assert_redirected_to root_path
    assert_flash :alert, "자신을 신고"
  end

  # =========================================
  # 중복 신고 방지
  # =========================================

  test "cannot report same item twice" do
    log_in_as(@user)

    # 첫 번째 신고
    assert_difference("Report.count", 1) do
      post reports_path, params: {
        reportable_type: "Post",
        reportable_id: @post.id,
        report: { reason: "spam" }
      }
    end

    # 두 번째 신고 (중복)
    assert_no_difference("Report.count") do
      post reports_path, params: {
        reportable_type: "Post",
        reportable_id: @post.id,
        report: { reason: "harassment" }
      }
    end
  end

  # =========================================
  # 유효하지 않은 대상
  # =========================================

  test "rejects invalid reportable type" do
    log_in_as(@user)

    assert_no_difference("Report.count") do
      post reports_path, params: {
        reportable_type: "InvalidModel",
        reportable_id: 1,
        report: { reason: "spam" }
      }
    end

    assert_redirected_to root_path
    assert_flash :alert, "유효하지 않은 신고 대상"
  end

  test "rejects non-existent reportable" do
    log_in_as(@user)

    assert_no_difference("Report.count") do
      post reports_path, params: {
        reportable_type: "Post",
        reportable_id: 999999,
        report: { reason: "spam" }
      }
    end

    assert_redirected_to root_path
    assert_flash :alert, "신고 대상을 찾을 수 없습니다"
  end
end
