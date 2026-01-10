# frozen_string_literal: true

require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @post = posts(:one)
  end

  # ==========================================================================
  # 기본 검색 (비로그인)
  # ==========================================================================

  test "should get index without query" do
    get search_url
    assert_response :success
    assert_select "input[type=search]"
  end

  test "should get index with query" do
    get search_url, params: { q: "테스트" }
    assert_response :success
  end

  test "should return empty results for non-matching query" do
    get search_url, params: { q: "존재하지않는검색어12345" }
    assert_response :success
  end

  # ==========================================================================
  # 탭별 검색
  # ==========================================================================

  test "should search all tab by default" do
    get search_url, params: { q: @user.name }
    assert_response :success
    assert_equal "all", assigns(:tab)
  end

  test "should search users tab" do
    get search_url, params: { q: @user.name, tab: "users" }
    assert_response :success
    assert_equal "users", assigns(:tab)
    assert assigns(:users).any?
    assert_empty assigns(:posts)
  end

  test "should search posts tab" do
    get search_url, params: { q: @post.title, tab: "posts" }
    assert_response :success
    assert_equal "posts", assigns(:tab)
    assert assigns(:posts).any?
    assert_empty assigns(:users)
  end

  test "should fallback to all tab for invalid tab" do
    get search_url, params: { q: "test", tab: "invalid" }
    assert_response :success
    assert_equal "all", assigns(:tab)
  end

  # ==========================================================================
  # 카테고리 필터 (게시글)
  # ==========================================================================

  test "should filter posts by community category" do
    get search_url, params: { q: "a", tab: "posts", category: "community" }
    assert_response :success
    assert_equal "community", assigns(:category)
  end

  test "should filter posts by hiring category" do
    get search_url, params: { q: "a", tab: "posts", category: "hiring" }
    assert_response :success
    assert_equal "hiring", assigns(:category)
  end

  test "should filter posts by seeking category" do
    get search_url, params: { q: "a", tab: "posts", category: "seeking" }
    assert_response :success
    assert_equal "seeking", assigns(:category)
  end

  test "should fallback to all category for invalid category" do
    get search_url, params: { q: "test", tab: "posts", category: "invalid" }
    assert_response :success
    assert_equal "all", assigns(:category)
  end

  # ==========================================================================
  # 페이지네이션
  # ==========================================================================

  test "should paginate users" do
    get search_url, params: { q: "a", tab: "users", page: 1 }
    assert_response :success
    assert assigns(:users_page).is_a?(Integer)
    assert assigns(:users_total_pages).is_a?(Integer)
  end

  test "should paginate posts" do
    get search_url, params: { q: "a", tab: "posts", page: 1 }
    assert_response :success
    assert assigns(:posts_page).is_a?(Integer)
    assert assigns(:posts_total_pages).is_a?(Integer)
  end

  # ==========================================================================
  # 실시간 검색 (XHR)
  # ==========================================================================

  test "should return partial for live search request" do
    get search_url, params: { q: "test", live: "true" }, xhr: true
    assert_response :success
    # 파셜이 렌더링되었는지 확인
    assert_not response.body.include?("<!DOCTYPE html>")
  end

  # ==========================================================================
  # 모달 검색
  # ==========================================================================

  test "should return modal results for modal search request" do
    get search_url, params: { q: "test", modal: "true" }
    assert_response :success
  end

  test "should return drilldown results for drilldown request" do
    get search_url, params: { q: "test", modal: "true", drilldown: "true", tab: "users" }
    assert_response :success
  end

  # ==========================================================================
  # 최근 검색어 (로그인 필요)
  # ==========================================================================

  test "should save recent search when logged in" do
    log_in_as(@user)
    get search_url, params: { q: "저장할검색어" }
    assert_response :success

    # 쿠키에 저장되었는지 확인
    assert cookies[:recent_searches].present?
    recent = JSON.parse(cookies[:recent_searches])
    assert_includes recent, "저장할검색어"
  end

  test "should not save recent search for live search" do
    log_in_as(@user)
    cookies[:recent_searches] = [].to_json

    get search_url, params: { q: "라이브검색어", live: "true" }, xhr: true
    assert_response :success

    # 쿠키가 업데이트되지 않았는지 확인
    recent = JSON.parse(cookies[:recent_searches])
    assert_not_includes recent, "라이브검색어"
  end

  test "should delete recent search" do
    log_in_as(@user)
    cookies[:recent_searches] = [ "검색어1", "검색어2" ].to_json

    delete destroy_recent_search_url, params: { query: "검색어1" }
    assert_redirected_to search_url

    recent = JSON.parse(cookies[:recent_searches])
    assert_not_includes recent, "검색어1"
    assert_includes recent, "검색어2"
  end

  test "should clear all recent searches" do
    log_in_as(@user)
    cookies[:recent_searches] = [ "검색어1", "검색어2" ].to_json

    delete clear_recent_searches_url
    assert_redirected_to search_url

    # 쿠키 삭제 시 nil 또는 빈 문자열
    assert cookies[:recent_searches].blank?
  end

  # ==========================================================================
  # 보안 테스트
  # ==========================================================================

  test "should sanitize SQL special characters in query" do
    # SQL Injection 시도가 안전하게 처리되는지 확인
    get search_url, params: { q: "'; DROP TABLE users; --" }
    assert_response :success
  end

  test "should handle very long query" do
    long_query = "a" * 1000
    get search_url, params: { q: long_query }
    assert_response :success
  end

  test "should handle empty query" do
    get search_url, params: { q: "" }
    assert_response :success
    assert_empty assigns(:users)
    assert_empty assigns(:posts)
  end

  test "should handle whitespace only query" do
    get search_url, params: { q: "   " }
    assert_response :success
    assert_empty assigns(:users)
    assert_empty assigns(:posts)
  end
end
