require "test_helper"

class Admin::AiUsagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @user = users(:one)
    # Sign in as admin (fixture password is 'test1234')
    post login_path, params: { email: @admin.email, password: "test1234" }
  end

  test "should update bonus credits" do
    original_bonus = @user.ai_bonus_credits

    patch update_bonus_admin_ai_usage_path(@user), params: { bonus: 10 }

    assert_redirected_to admin_ai_usage_path(@user)
    @user.reload
    assert_equal 10, @user.ai_bonus_credits
    assert_includes flash[:notice], "보너스 크레딧이 10개로 설정"

    # Cleanup
    @user.update!(ai_bonus_credits: original_bonus)
  end

  test "should set remaining by calculating bonus" do
    # Reset to known state
    @user.update!(ai_bonus_credits: 0, ai_analysis_limit: 5)

    patch set_remaining_admin_ai_usage_path(@user), params: { remaining: 20 }

    assert_redirected_to admin_ai_usage_path(@user)
    @user.reload

    # With limit=5, used=0, remaining=20 needs bonus=15
    expected_bonus = 20 - (5 - @user.idea_analyses.count)
    assert_equal expected_bonus, @user.ai_bonus_credits
    assert_equal 20, @user.ai_analyses_remaining

    # Cleanup
    @user.update!(ai_bonus_credits: 0)
  end

  test "should update limit" do
    patch update_limit_admin_ai_usage_path(@user), params: { limit: 50 }

    assert_redirected_to admin_ai_usage_path(@user)
    @user.reload
    assert_equal 50, @user.ai_analysis_limit

    # Cleanup
    @user.update!(ai_analysis_limit: nil)
  end

  test "should reset limit to default when set to 0" do
    @user.update!(ai_analysis_limit: 50)

    patch update_limit_admin_ai_usage_path(@user), params: { limit: 0 }

    assert_redirected_to admin_ai_usage_path(@user)
    @user.reload
    assert_nil @user.ai_analysis_limit
  end

  test "bonus credits should affect remaining count" do
    @user.update!(ai_bonus_credits: 0, ai_analysis_limit: 5)
    base_remaining = @user.ai_analyses_remaining

    @user.update!(ai_bonus_credits: 10)
    assert_equal base_remaining + 10, @user.ai_analyses_remaining

    # Cleanup
    @user.update!(ai_bonus_credits: 0)
  end
end
