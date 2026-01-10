# frozen_string_literal: true

require "test_helper"

module Search
  class RecentSearchesManagerTest < ActiveSupport::TestCase
    setup do
      @cookies = MockCookies.new
      @manager = RecentSearchesManager.new(@cookies)
    end

    # ==========================================================================
    # Save Tests
    # ==========================================================================

    test "save adds query to recent searches" do
      @manager.save("창업")

      assert_equal ["창업"], @manager.all
    end

    test "save moves duplicate to front" do
      @manager.save("창업")
      @manager.save("개발자")
      @manager.save("창업")

      assert_equal ["창업", "개발자"], @manager.all
    end

    test "save limits to MAX_RECENT_SEARCHES" do
      12.times { |i| @manager.save("query#{i}") }

      assert_equal RecentSearchesManager::MAX_RECENT_SEARCHES, @manager.all.size
      assert_equal "query11", @manager.all.first
      assert_equal "query2", @manager.all.last
    end

    test "save ignores blank queries" do
      @manager.save("")
      @manager.save(nil)
      @manager.save("   ")

      assert_empty @manager.all
    end

    # ==========================================================================
    # All Tests
    # ==========================================================================

    test "all returns empty array when no cookie" do
      assert_equal [], @manager.all
    end

    test "all returns empty array for invalid JSON" do
      @cookies[RecentSearchesManager::COOKIE_KEY] = "invalid json"

      assert_equal [], @manager.all
    end

    # ==========================================================================
    # Delete Tests
    # ==========================================================================

    test "delete removes specific query" do
      @manager.save("창업")
      @manager.save("개발자")
      @manager.delete("창업")

      assert_equal ["개발자"], @manager.all
    end

    test "delete does nothing for non-existent query" do
      @manager.save("창업")
      @manager.delete("존재하지않음")

      assert_equal ["창업"], @manager.all
    end

    # ==========================================================================
    # Clear Tests
    # ==========================================================================

    test "clear removes all recent searches" do
      @manager.save("창업")
      @manager.save("개발자")
      @manager.clear

      assert_equal [], @manager.all
    end

    # ==========================================================================
    # Cookie Tests
    # ==========================================================================

    test "cookie has correct expiry" do
      @manager.save("test")

      cookie_data = @cookies.raw_data[RecentSearchesManager::COOKIE_KEY]
      assert cookie_data[:expires].present?
      assert cookie_data[:expires] > Time.current + 29.days
    end
  end

  # Mock cookies class for testing
  class MockCookies
    attr_reader :raw_data

    def initialize
      @raw_data = {}
    end

    def [](key)
      data = @raw_data[key]
      data.is_a?(Hash) ? data[:value] : data
    end

    def []=(key, value)
      @raw_data[key] = value
    end

    def delete(key)
      @raw_data.delete(key)
    end
  end
end
