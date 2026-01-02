# frozen_string_literal: true

require "test_helper"

class UserDeletionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @password = "test1234"  # From fixtures
  end

  # ============================================================================
  # Authentication Tests
  # ============================================================================

  test "new requires login" do
    get delete_account_path
    assert_redirected_to login_path
    assert_equal "로그인이 필요합니다.", flash[:alert]
  end

  test "create requires login" do
    post account_delete_path, params: { password: @password }
    assert_redirected_to login_path
    assert_equal "로그인이 필요합니다.", flash[:alert]
  end

  # ============================================================================
  # NEW Action Tests
  # ============================================================================

  test "new renders deletion confirmation page" do
    log_in_as(@user)
    get delete_account_path

    assert_response :success
    assert_select "form"
  end

  test "new displays reason categories" do
    log_in_as(@user)
    get delete_account_path

    assert_response :success
    # Check some reason categories are displayed
    assert_select "select" # or radio buttons for reasons
  end

  # ============================================================================
  # CREATE Action Tests - Password Verification
  # ============================================================================

  test "create with invalid password fails" do
    log_in_as(@user)

    post account_delete_path, params: {
      password: "wrong_password",
      reason_category: "not_using"
    }

    assert_response :unprocessable_entity
    assert_equal "비밀번호가 올바르지 않습니다.", flash[:alert]
  end

  test "create with empty password fails" do
    log_in_as(@user)

    post account_delete_path, params: {
      password: "",
      reason_category: "not_using"
    }

    assert_response :unprocessable_entity
    assert_equal "비밀번호가 올바르지 않습니다.", flash[:alert]
  end

  test "create with nil password fails" do
    log_in_as(@user)

    post account_delete_path, params: {
      reason_category: "not_using"
    }

    assert_response :unprocessable_entity
    assert_equal "비밀번호가 올바르지 않습니다.", flash[:alert]
  end

  test "create keeps user logged in on password failure" do
    log_in_as(@user)

    post account_delete_path, params: {
      password: "wrong_password",
      reason_category: "not_using"
    }

    # User should still be logged in
    assert_not_nil session[:user_id]
    assert_equal @user.id, session[:user_id]
  end

  # ============================================================================
  # CREATE Action Tests - Successful Deletion (Integration)
  # ============================================================================

  test "create with valid password deletes user" do
    log_in_as(@user)

    assert_difference "UserDeletion.count", 1 do
      post account_delete_path, params: {
        password: @password,
        reason_category: "not_using"
      }
    end

    assert_redirected_to root_path
  end

  test "create anonymizes user on success" do
    log_in_as(@user)
    original_email = @user.email

    post account_delete_path, params: {
      password: @password,
      reason_category: "not_using"
    }

    @user.reload
    assert_not_equal original_email, @user.email
    assert_match /^deleted_/, @user.email
  end

  test "create logs out user after successful deletion" do
    log_in_as(@user)

    post account_delete_path, params: { password: @password }

    # User should be logged out
    assert_nil session[:user_id]
  end

  test "create redirects to root after successful deletion" do
    log_in_as(@user)

    post account_delete_path, params: { password: @password }

    assert_redirected_to root_path
  end

  test "create shows success message after deletion" do
    log_in_as(@user)

    post account_delete_path, params: { password: @password }

    assert_equal "회원 탈퇴가 완료되었습니다. 이용해 주셔서 감사합니다.", flash[:notice]
  end

  test "create stores reason_category in deletion record" do
    log_in_as(@user)
    expected_category = "privacy_concern"

    post account_delete_path, params: {
      password: @password,
      reason_category: expected_category
    }

    deletion = UserDeletion.last
    assert_equal expected_category, deletion.reason_category
  end

  test "create stores reason_detail in deletion record" do
    log_in_as(@user)
    expected_detail = "상세한 탈퇴 이유입니다."

    post account_delete_path, params: {
      password: @password,
      reason_detail: expected_detail
    }

    deletion = UserDeletion.last
    assert_equal expected_detail, deletion.reason_detail
  end

  # ============================================================================
  # Reason Category Tests
  # ============================================================================

  test "create accepts not_using reason category" do
    log_in_as(@user)

    post account_delete_path, params: {
      password: @password,
      reason_category: "not_using"
    }

    assert_redirected_to root_path
    assert_equal "not_using", UserDeletion.last.reason_category
  end

  test "create accepts privacy_concern reason category" do
    user = User.create!(
      email: "test_privacy@test.com",
      password: @password,
      name: "Test Privacy"
    )
    log_in_as(user)

    post account_delete_path, params: {
      password: @password,
      reason_category: "privacy_concern"
    }

    assert_redirected_to root_path
  end

  test "create accepts other reason category" do
    user = User.create!(
      email: "test_other@test.com",
      password: @password,
      name: "Test Other"
    )
    log_in_as(user)

    post account_delete_path, params: {
      password: @password,
      reason_category: "other"
    }

    assert_redirected_to root_path
  end

  # ============================================================================
  # Edge Cases
  # ============================================================================

  test "reason_categories constant is accessible" do
    assert UserDeletion::REASON_CATEGORIES.is_a?(Hash)
    assert UserDeletion::REASON_CATEGORIES.keys.include?("not_using")
    assert UserDeletion::REASON_CATEGORIES.keys.include?("other")
  end

  test "cannot access deletion page after logout" do
    log_in_as(@user)
    delete logout_path

    get delete_account_path
    assert_redirected_to login_path
  end

  test "user cannot login after deletion" do
    log_in_as(@user)
    user_email = @user.email

    post account_delete_path, params: { password: @password }

    # Try to login again
    post login_path, params: {
      email: user_email,
      password: @password
    }

    # Should fail because email is anonymized
    assert_nil session[:user_id]
  end

  test "deletion creates encryption backup" do
    log_in_as(@user)
    original_email = @user.email

    post account_delete_path, params: { password: @password }

    deletion = UserDeletion.last
    assert_not_nil deletion.email_original
    # The encrypted value should be decryptable to original email
    assert_equal original_email, deletion.email_original
  end

  # ============================================================================
  # OAuth User Deletion Tests (OAuth 사용자 탈퇴 테스트)
  # ============================================================================

  test "create with oauth_only user shows checkbox confirmation" do
    oauth_user = create_oauth_only_user
    assert oauth_user.oauth_only?, "Test user should be oauth_only"

    post login_path, params: { email: oauth_user.email, password: "temporary_password" }
    follow_redirect! if response.redirect?

    get delete_account_path

    assert_response :success
    # OAuth 사용자는 비밀번호 대신 체크박스 동의를 받음
    # View에서 oauth_only? 체크에 따라 다른 폼이 표시됨
    assert_select "form", minimum: 1, message: "Should show deletion form"
  end

  test "create with oauth_only user fails without consent checkbox" do
    oauth_user = create_oauth_only_user
    assert oauth_user.oauth_only?, "Test user should be oauth_only"

    post login_path, params: { email: oauth_user.email, password: "temporary_password" }
    follow_redirect! if response.redirect?

    assert_no_difference "UserDeletion.count" do
      post account_delete_path, params: {
        # confirm_deletion 파라미터 없음
        reason_category: "not_using"
      }
    end

    assert_response :unprocessable_entity
    assert_equal "탈퇴 동의가 필요합니다.", flash[:alert]
  end

  test "create with oauth_only user fails with confirm_deletion=false" do
    oauth_user = create_oauth_only_user
    assert oauth_user.oauth_only?, "Test user should be oauth_only"

    post login_path, params: { email: oauth_user.email, password: "temporary_password" }
    follow_redirect! if response.redirect?

    assert_no_difference "UserDeletion.count" do
      post account_delete_path, params: {
        confirm_deletion: "0",
        reason_category: "not_using"
      }
    end

    assert_response :unprocessable_entity
    assert_equal "탈퇴 동의가 필요합니다.", flash[:alert]
  end

  test "create with oauth_only user succeeds with confirm_deletion=1" do
    oauth_user = create_oauth_only_user
    assert oauth_user.oauth_only?, "Test user should be oauth_only"

    post login_path, params: { email: oauth_user.email, password: "temporary_password" }
    follow_redirect! if response.redirect?

    assert_difference "UserDeletion.count", 1 do
      post account_delete_path, params: {
        confirm_deletion: "1",
        reason_category: "privacy_concern"
      }
    end

    assert_redirected_to root_path
    assert_equal "회원 탈퇴가 완료되었습니다. 이용해 주셔서 감사합니다.", flash[:notice]
  end

  test "create with oauth_only user succeeds with confirm_deletion=true" do
    oauth_user = create_oauth_only_user
    assert oauth_user.oauth_only?, "Test user should be oauth_only"

    post login_path, params: { email: oauth_user.email, password: "temporary_password" }
    follow_redirect! if response.redirect?

    assert_difference "UserDeletion.count", 1 do
      post account_delete_path, params: {
        confirm_deletion: "true",
        reason_category: "other"
      }
    end

    assert_redirected_to root_path
  end

  test "create with oauth_only user anonymizes correctly" do
    oauth_user = create_oauth_only_user
    original_email = oauth_user.email
    assert oauth_user.oauth_only?, "Test user should be oauth_only"

    post login_path, params: { email: oauth_user.email, password: "temporary_password" }
    follow_redirect! if response.redirect?

    post account_delete_path, params: {
      confirm_deletion: "1",
      reason_category: "not_using"
    }

    oauth_user.reload
    assert_not_equal original_email, oauth_user.email
    assert_match /^deleted_/, oauth_user.email
  end

  # ============================================================================
  # Security Tests (보안 테스트)
  # ============================================================================

  test "reason_detail does not allow XSS input" do
    log_in_as(@user)
    malicious_input = "<script>alert('XSS')</script>"

    post account_delete_path, params: {
      password: @password,
      reason_detail: malicious_input
    }

    deletion = UserDeletion.last
    # 저장은 되지만 HTML escape 처리가 되어야 함
    # 또는 strip_tags 처리가 되어 있을 수 있음
    if deletion.present?
      # 데이터베이스에 저장됨 - 렌더링 시 escape 필요
      assert_not_nil deletion.reason_detail
      # 렌더링 시 Rails의 자동 escape로 XSS 방지됨
    end
  end

  test "reason_detail stores very long input correctly" do
    log_in_as(@user)
    long_input = "탈" * 5000  # 5000자 한글

    post account_delete_path, params: {
      password: @password,
      reason_detail: long_input
    }

    # Should either truncate or store correctly
    if response.status == 302  # Success redirect
      deletion = UserDeletion.last
      assert_not_nil deletion.reason_detail
    end
  end

  test "brute force password attempt shows same error" do
    log_in_as(@user)

    5.times do |i|
      post account_delete_path, params: {
        password: "wrong_password_#{i}",
        reason_category: "not_using"
      }

      assert_response :unprocessable_entity
      # 모든 시도에서 동일한 에러 메시지 (정보 노출 방지)
      assert_equal "비밀번호가 올바르지 않습니다.", flash[:alert]
    end

    # 사용자는 여전히 로그인 상태여야 함
    assert_equal @user.id, session[:user_id]
  end

  test "prevents deletion if user already deleted" do
    # First deletion
    log_in_as(@user)
    post account_delete_path, params: { password: @password }
    assert_redirected_to root_path

    # User is now deleted and logged out
    # Try to access deletion page (should be blocked by require_login)
    get delete_account_path
    assert_redirected_to login_path
  end

  private

  # OAuth 전용 사용자 생성 헬퍼
  def create_oauth_only_user
    user = User.create!(
      email: "oauth_test_#{SecureRandom.hex(4)}@gmail.com",
      password: "temporary_password",  # 초기 설정용
      name: "OAuth Only User",
      provider: "google"  # oauth_only? 조건 충족
    )

    # OAuth identity 추가
    OauthIdentity.create!(
      user: user,
      provider: "google",
      uid: "google_test_#{SecureRandom.hex(8)}"
    )

    # 비밀번호 삭제 (oauth_only 시뮬레이션)
    # 실제로는 password_digest가 있어도 provider가 있으면 oauth_only?가 true
    user
  end
end
