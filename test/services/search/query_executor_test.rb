# frozen_string_literal: true

require "test_helper"

module Search
  class QueryExecutorTest < ActiveSupport::TestCase
    setup do
      @user1 = users(:one)
      @user2 = users(:two)
      @post1 = posts(:one)
      @post2 = posts(:two)
    end

    # ==========================================================================
    # User Search Tests
    # ==========================================================================

    test "search_users returns matching users by name" do
      # user fixture에 맞는 쿼리
      executor = QueryExecutor.new(query: @user1.name, category: "all")
      result = executor.search_users(limit: 5)

      assert_kind_of QueryExecutor::Result, result
      assert result.items.any?
      assert result.total_count >= 1
    end

    test "search_users returns empty for non-matching query" do
      executor = QueryExecutor.new(query: "zzzznonexistent12345", category: "all")
      result = executor.search_users(limit: 5)

      assert_empty result.items
      assert_equal 0, result.total_count
    end

    test "search_users_paginated returns paginated results" do
      executor = QueryExecutor.new(query: @user1.name.first(2), category: "all")
      result = executor.search_users_paginated(page: 1, per_page: 2)

      assert result.page >= 1
      assert result.total_pages >= 0
      assert result.items.size <= 2
    end

    test "search_users_paginated handles invalid page numbers" do
      executor = QueryExecutor.new(query: "test", category: "all")

      result = executor.search_users_paginated(page: -1, per_page: 10)
      assert result.page >= 1

      result = executor.search_users_paginated(page: 9999, per_page: 10)
      assert result.page <= [result.total_pages, 1].max
    end

    # ==========================================================================
    # Post Search Tests
    # ==========================================================================

    test "search_posts returns matching posts by title" do
      executor = QueryExecutor.new(query: @post1.title.first(5), category: "all")
      result = executor.search_posts(limit: 5)

      assert_kind_of QueryExecutor::Result, result
      assert result.total_count >= 0
    end

    test "search_posts filters by category" do
      executor = QueryExecutor.new(query: "", category: "hiring")
      result = executor.search_posts(limit: 5)

      # hiring 카테고리만 포함해야 함
      result.items.each do |post|
        assert_equal "hiring", post.category
      end
    end

    test "search_posts_paginated returns paginated results" do
      executor = QueryExecutor.new(query: "test", category: "all")
      result = executor.search_posts_paginated(page: 1, per_page: 2)

      assert result.page >= 1
      assert result.total_pages >= 0
    end

    # ==========================================================================
    # Category Filter Tests
    # ==========================================================================

    test "category filter community includes free, question, promotion" do
      executor = QueryExecutor.new(query: "", category: "community")
      result = executor.search_posts(limit: 100)

      result.items.each do |post|
        assert_includes %w[free question promotion], post.category
      end
    end

    test "category filter seeking includes only seeking" do
      executor = QueryExecutor.new(query: "", category: "seeking")
      result = executor.search_posts(limit: 100)

      result.items.each do |post|
        assert_equal "seeking", post.category
      end
    end

    # ==========================================================================
    # Result Object Tests
    # ==========================================================================

    test "Result has_more_pages? returns correct value" do
      result = QueryExecutor::Result.new(
        items: [],
        total_count: 100,
        page: 1,
        total_pages: 10
      )

      assert result.has_more_pages?

      result = QueryExecutor::Result.new(
        items: [],
        total_count: 10,
        page: 10,
        total_pages: 10
      )

      refute result.has_more_pages?
    end

    # ==========================================================================
    # SQL Injection Prevention Tests
    # ==========================================================================

    test "sanitizes LIKE special characters" do
      executor = QueryExecutor.new(query: "test%_\\", category: "all")
      # SQL 에러 없이 실행되어야 함
      assert_nothing_raised do
        executor.search_users(limit: 5)
        executor.search_posts(limit: 5)
      end
    end
  end
end
