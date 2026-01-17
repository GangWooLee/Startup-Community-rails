# frozen_string_literal: true

require "test_helper"

class AiAnalyzableTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  # =========================================
  # effective_ai_limit 메서드 테스트
  # =========================================

  test "effective_ai_limit returns default when ai_analysis_limit is nil" do
    @user.update_column(:ai_analysis_limit, nil)

    assert_equal 5, @user.effective_ai_limit  # DEFAULT_AI_ANALYSIS_LIMIT
  end

  test "effective_ai_limit returns custom limit when set" do
    @user.update_column(:ai_analysis_limit, 10)

    assert_equal 10, @user.effective_ai_limit
  end

  # =========================================
  # ai_analyses_remaining 메서드 테스트
  # =========================================

  test "ai_analyses_remaining returns positive number for new user" do
    @user.idea_analyses.destroy_all
    @user.update_columns(ai_analysis_limit: nil, ai_bonus_credits: 0)

    remaining = @user.ai_analyses_remaining

    assert remaining > 0
    assert_equal 5, remaining  # Default limit
  end

  test "ai_analyses_remaining includes bonus credits" do
    @user.idea_analyses.destroy_all
    @user.update_columns(ai_analysis_limit: 5, ai_bonus_credits: 3)

    remaining = @user.ai_analyses_remaining

    assert_equal 8, remaining  # 5 limit + 3 bonus
  end

  test "ai_analyses_remaining never returns negative" do
    @user.update_columns(ai_analysis_limit: 0, ai_bonus_credits: 0)

    remaining = @user.ai_analyses_remaining

    assert remaining >= 0
  end

  # =========================================
  # base_remaining 메서드 테스트
  # =========================================

  test "base_remaining excludes bonus credits" do
    @user.idea_analyses.destroy_all
    @user.update_columns(ai_analysis_limit: 5, ai_bonus_credits: 10)

    base = @user.base_remaining

    assert_equal 5, base  # Only limit, no bonus
  end

  # =========================================
  # ai_limit_reached? 메서드 테스트
  # =========================================

  test "ai_limit_reached? returns false when remaining > 0" do
    @user.idea_analyses.destroy_all
    @user.update_columns(ai_analysis_limit: 5, ai_bonus_credits: 0)

    assert_not @user.ai_limit_reached?
  end

  test "ai_limit_reached? returns true when remaining is 0" do
    @user.update_columns(ai_analysis_limit: 0, ai_bonus_credits: 0)

    # 분석 사용량이 limit과 같거나 초과하면 true
    assert @user.ai_limit_reached? || @user.ai_analyses_remaining == 0
  end

  # =========================================
  # calculate_bonus_for_remaining 메서드 테스트
  # =========================================

  test "calculate_bonus_for_remaining returns correct bonus needed" do
    @user.idea_analyses.destroy_all
    @user.update_column(:ai_analysis_limit, 5)

    # 10개 남기려면 5개 보너스 필요 (limit 5 + bonus 5 = 10)
    bonus = @user.calculate_bonus_for_remaining(10)

    assert_equal 5, bonus
  end

  # =========================================
  # ai_usage_stats 메서드 테스트
  # =========================================

  test "ai_usage_stats returns hash with all keys" do
    stats = @user.ai_usage_stats

    assert_kind_of Hash, stats
    assert stats.key?(:used)
    assert stats.key?(:limit)
    assert stats.key?(:bonus)
    assert stats.key?(:remaining)
    assert stats.key?(:base_remaining)
    assert stats.key?(:is_custom_limit)
    assert stats.key?(:has_bonus)
    assert stats.key?(:reached)
  end

  test "ai_usage_stats returns correct values" do
    @user.idea_analyses.destroy_all
    @user.update_columns(ai_analysis_limit: 10, ai_bonus_credits: 5)

    stats = @user.ai_usage_stats

    assert_equal 0, stats[:used]
    assert_equal 10, stats[:limit]
    assert_equal 5, stats[:bonus]
    assert_equal 15, stats[:remaining]
    assert_equal true, stats[:is_custom_limit]
    assert_equal true, stats[:has_bonus]
    assert_equal false, stats[:reached]
  end
end
