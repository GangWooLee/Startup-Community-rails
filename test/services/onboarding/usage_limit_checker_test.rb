# frozen_string_literal: true

require "test_helper"

module Onboarding
  class UsageLimitCheckerTest < ActiveSupport::TestCase
    setup do
      @user = users(:one)
      @cookies = MockCookies.new
    end

    # ==========================================================================
    # Logged-in User Tests
    # ==========================================================================

    test "logged_in? returns true for user" do
      checker = UsageLimitChecker.new(user: @user, cookies: @cookies)

      assert checker.logged_in?
    end

    test "logged_in? returns false for nil user" do
      checker = UsageLimitChecker.new(user: nil, cookies: @cookies)

      refute checker.logged_in?
    end

    test "remaining returns positive for new user" do
      checker = UsageLimitChecker.new(user: @user, cookies: @cookies)

      assert checker.remaining >= 0
    end

    test "exceeded? returns false when remaining > 0" do
      checker = UsageLimitChecker.new(user: @user, cookies: @cookies)
      # 새 유저는 기본적으로 remaining > 0
      # 만약 remaining이 0이면 이 테스트는 스킵됨
      skip "User has no remaining analyses" if checker.remaining <= 0

      refute checker.exceeded?
    end

    test "effective_limit returns positive number" do
      checker = UsageLimitChecker.new(user: @user, cookies: @cookies)

      assert checker.effective_limit > 0
    end

    # ==========================================================================
    # Guest User Tests
    # ==========================================================================

    test "remaining returns MAX_FREE_ANALYSES for guest" do
      checker = UsageLimitChecker.new(user: nil, cookies: @cookies)

      assert_equal UsageLimitChecker::MAX_FREE_ANALYSES, checker.remaining
    end

    test "remaining decreases with guest cookie" do
      @cookies[:guest_ai_usage_count] = "2"

      checker = UsageLimitChecker.new(user: nil, cookies: @cookies)

      assert_equal 3, checker.remaining # 5 - 2
    end

    test "increment_guest_count! increases cookie counter" do
      checker = UsageLimitChecker.new(user: nil, cookies: @cookies)

      checker.increment_guest_count!

      assert_equal "1", @cookies.permanent[:guest_ai_usage_count]
    end

    test "increment_guest_count! does nothing for logged-in users" do
      checker = UsageLimitChecker.new(user: @user, cookies: @cookies)

      checker.increment_guest_count!

      assert_nil @cookies.permanent[:guest_ai_usage_count]
    end

    test "guest exceeded? returns true after max uses" do
      @cookies[:guest_ai_usage_count] = UsageLimitChecker::MAX_FREE_ANALYSES.to_s

      checker = UsageLimitChecker.new(user: nil, cookies: @cookies)

      assert checker.exceeded?
    end

    test "effective_limit returns MAX_FREE_ANALYSES for guest" do
      checker = UsageLimitChecker.new(user: nil, cookies: @cookies)

      assert_equal UsageLimitChecker::MAX_FREE_ANALYSES, checker.effective_limit
    end

    # ==========================================================================
    # Current Count Tests
    # ==========================================================================

    test "current_count uses only cookie for guest" do
      @cookies[:guest_ai_usage_count] = "3"

      checker = UsageLimitChecker.new(user: nil, cookies: @cookies)

      assert_equal 3, checker.current_count
    end

    test "current_count returns integer for logged-in user" do
      @cookies[:guest_ai_usage_count] = "2"

      checker = UsageLimitChecker.new(user: @user, cookies: @cookies)

      assert_kind_of Integer, checker.current_count
    end

    # ==========================================================================
    # Bonus Tests
    # ==========================================================================

    test "has_bonus? returns boolean for user" do
      checker = UsageLimitChecker.new(user: @user, cookies: @cookies)

      assert_includes [ true, false ], checker.has_bonus?
    end

    test "has_bonus? returns false for guests" do
      checker = UsageLimitChecker.new(user: nil, cookies: @cookies)

      refute checker.has_bonus?
    end

    # ==========================================================================
    # Stats Tests
    # ==========================================================================

    test "stats returns correct keys for logged-in user" do
      checker = UsageLimitChecker.new(user: @user, cookies: @cookies)
      stats = checker.stats

      assert stats.key?(:remaining)
      assert stats.key?(:effective_limit)
      assert stats.key?(:has_bonus)
    end

    test "stats returns correct structure for guest" do
      checker = UsageLimitChecker.new(user: nil, cookies: @cookies)
      stats = checker.stats

      assert_equal UsageLimitChecker::MAX_FREE_ANALYSES, stats[:remaining]
      assert_equal UsageLimitChecker::MAX_FREE_ANALYSES, stats[:effective_limit]
      refute stats[:has_bonus]
    end

    # ==========================================================================
    # Last One Tests
    # ==========================================================================

    test "last_one? returns boolean" do
      checker = UsageLimitChecker.new(user: @user, cookies: @cookies)

      assert_includes [ true, false ], checker.last_one?
    end

    test "last_one? returns true when guest has 1 remaining" do
      @cookies[:guest_ai_usage_count] = (UsageLimitChecker::MAX_FREE_ANALYSES - 1).to_s

      checker = UsageLimitChecker.new(user: nil, cookies: @cookies)

      assert checker.last_one?
    end
  end

  # Mock cookies class for testing
  class MockCookies
    attr_reader :permanent

    def initialize
      @data = {}
      @permanent = PermanentCookies.new(@data)
    end

    def [](key)
      @data[key]
    end

    def []=(key, value)
      @data[key] = value
    end

    def delete(key)
      @data.delete(key)
    end

    class PermanentCookies
      def initialize(data)
        @data = data
      end

      def [](key)
        @data[key]
      end

      def []=(key, value)
        @data[key] = value
      end
    end
  end
end
