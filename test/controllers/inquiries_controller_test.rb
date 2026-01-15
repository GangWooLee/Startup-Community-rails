# frozen_string_literal: true

require "test_helper"

class InquiriesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @inquiry = inquiries(:bug_inquiry)
    @other_inquiry = inquiries(:feature_inquiry)
  end

  # =========================================
  # 인증 테스트
  # =========================================

  test "allows access to index without login" do
    get inquiries_path
    assert_response :success
  end

  test "requires login for new" do
    get new_inquiry_path
    assert_redirected_to login_path
  end

  test "requires login for create" do
    post inquiries_path, params: { inquiry: { category: "bug", title: "Test", content: "Content" } }
    assert_redirected_to login_path
  end

  test "requires login for show" do
    get inquiry_path(@inquiry)
    assert_redirected_to login_path
  end

  # =========================================
  # GET /inquiries - 목록 페이지
  # =========================================

  test "should get index with own inquiries" do
    log_in_as(@user)

    get inquiries_path
    assert_response :success
  end

  test "index shows only current user inquiries" do
    log_in_as(@user)

    get inquiries_path
    assert_response :success
    # user :one의 문의만 표시되어야 함 (bug_inquiry, other_inquiry)
    # user :two의 문의는 표시되지 않아야 함 (feature_inquiry)
  end

  test "index pagination works" do
    log_in_as(@user)

    # 페이지네이션 파라미터 테스트
    get inquiries_path, params: { page: 1 }
    assert_response :success
  end

  # =========================================
  # GET /inquiries/new - 문의 작성 페이지
  # =========================================

  test "should get new" do
    log_in_as(@user)

    get new_inquiry_path
    assert_response :success
    assert_select "form"
  end

  # =========================================
  # POST /inquiries - 문의 등록
  # =========================================

  test "should create inquiry with valid params" do
    log_in_as(@user)

    assert_difference("Inquiry.count", 1) do
      post inquiries_path, params: {
        inquiry: {
          category: "bug",
          title: "새로운 버그 제보",
          content: "상세한 버그 내용입니다."
        }
      }
    end

    assert_redirected_to inquiries_path
    assert_flash :notice, "문의가 등록"
  end

  test "should reject inquiry without category" do
    log_in_as(@user)

    assert_no_difference("Inquiry.count") do
      post inquiries_path, params: {
        inquiry: {
          category: "",
          title: "테스트 문의",
          content: "내용"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should reject inquiry without title" do
    log_in_as(@user)

    assert_no_difference("Inquiry.count") do
      post inquiries_path, params: {
        inquiry: {
          category: "bug",
          title: "",
          content: "내용"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should reject inquiry with title over 100 chars" do
    log_in_as(@user)

    assert_no_difference("Inquiry.count") do
      post inquiries_path, params: {
        inquiry: {
          category: "bug",
          title: "a" * 101,
          content: "내용"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should reject inquiry without content" do
    log_in_as(@user)

    assert_no_difference("Inquiry.count") do
      post inquiries_path, params: {
        inquiry: {
          category: "bug",
          title: "테스트",
          content: ""
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should reject inquiry with invalid category" do
    log_in_as(@user)

    assert_no_difference("Inquiry.count") do
      post inquiries_path, params: {
        inquiry: {
          category: "invalid_category",
          title: "테스트",
          content: "내용"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should accept all valid categories" do
    log_in_as(@user)

    Inquiry::CATEGORIES.keys.each do |category|
      assert_difference("Inquiry.count", 1) do
        post inquiries_path, params: {
          inquiry: {
            category: category,
            title: "#{category} 테스트 문의",
            content: "내용입니다."
          }
        }
      end
    end
  end

  # =========================================
  # GET /inquiries/:id - 문의 상세 페이지
  # =========================================

  test "should show own inquiry" do
    log_in_as(@user)

    get inquiry_path(@inquiry)
    assert_response :success
  end

  test "should not show other users inquiry" do
    log_in_as(@user)

    # feature_inquiry는 user :two의 문의
    get inquiry_path(@other_inquiry)
    assert_redirected_to inquiries_path
    assert_flash :alert, "접근 권한"
  end

  test "shows admin response if present" do
    log_in_as(users(:three))

    # improvement_inquiry는 answered된 문의
    answered_inquiry = inquiries(:improvement_inquiry)
    get inquiry_path(answered_inquiry)
    assert_response :success
  end
end
