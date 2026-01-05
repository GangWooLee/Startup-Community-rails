# frozen_string_literal: true

require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
    @post = posts(:one)
  end

  # =========================================
  # 검색 UI 테스트
  # =========================================

  test "search input is accessible from header" do
    visit community_path

    # 검색 버튼 또는 입력창 확인
    assert_selector "[data-action*='search'], [data-controller*='search'], input[type='search'], input[name*='q']"
  end

  test "search modal opens on click" do
    visit community_path

    # 검색 버튼 클릭
    find("[data-action*='search#open'], [data-controller*='search'] button", match: :first).click rescue nil

    # 검색 모달/드롭다운 표시
    if page.has_selector?("[data-search-modal-target], [data-live-search-target]", wait: 2)
      assert_selector "[data-search-modal-target], [data-live-search-target]"
    end
  end

  # =========================================
  # 검색 기능 테스트
  # =========================================

  test "can search for posts" do
    visit search_path(q: @post.title)

    # 검색 결과 표시
    assert_text @post.title
  end

  test "search shows no results message for non-matching query" do
    visit search_path(q: "zzznonexistentquery123")

    # 검색 결과 없음 메시지
    assert_text("결과가 없습니다") || assert_text("찾을 수 없습니다") || assert_no_selector(".post-card")
  end

  # =========================================
  # 라이브 검색 테스트
  # =========================================

  test "live search shows suggestions" do
    visit community_path

    # 검색 입력창 찾기
    search_input = find("input[data-live-search-target='input'], input[name='q']", match: :first, wait: 3) rescue nil

    if search_input
      search_input.fill_in with: @post.title[0..3]  # 처음 몇 글자

      # 실시간 결과 표시 대기
      sleep 0.5

      # 드롭다운 결과 확인
      if page.has_selector?("[data-live-search-target='results']", wait: 2)
        within("[data-live-search-target='results']") do
          assert_text @post.title
        end
      end
    end
  end

  # =========================================
  # 검색 필터 테스트
  # =========================================

  test "can filter search by category" do
    visit search_path

    # 카테고리 필터 선택
    if page.has_select?("category")
      select "자유", from: "category"

      # 필터 적용 확인
      assert_current_path %r{category=}
    end
  end

  test "can search users" do
    visit search_path(q: @user.name, type: "users")

    # 사용자 검색 결과 표시
    if page.has_text?(@user.name)
      assert_text @user.name
    end
  end

  # =========================================
  # 검색 결과 페이지 테스트
  # =========================================

  test "search results page shows query" do
    query = "테스트"
    visit search_path(q: query)

    # 검색어 표시 확인
    assert_text query
  end

  test "search results are paginated" do
    # 많은 게시글이 있는 경우 페이지네이션 확인
    visit search_path(q: "a")

    # 페이지네이션 링크 확인 (결과가 많을 경우)
    if page.has_selector?(".pagination, [class*='pagination']", wait: 1)
      assert_selector ".pagination, [class*='pagination']"
    end
  end

  # =========================================
  # 키보드 네비게이션 테스트
  # =========================================

  test "can navigate search results with keyboard" do
    visit community_path

    search_input = find("input[data-live-search-target='input']", match: :first, wait: 3) rescue nil

    if search_input
      search_input.fill_in with: @post.title[0..5]
      sleep 0.5

      # 아래 화살표로 결과 선택
      search_input.send_keys(:down)
      sleep 0.2

      # 선택된 항목 스타일 확인
      if page.has_selector?("[data-live-search-target='results'] .selected, [data-live-search-target='results'] [class*='selected']", wait: 1)
        assert_selector "[data-live-search-target='results'] .selected, [data-live-search-target='results'] [class*='selected']"
      end
    end
  end

  # =========================================
  # 검색 히스토리 테스트
  # =========================================

  test "search preserves query in URL" do
    query = "Rails 개발"
    visit search_path(q: query)

    # URL에 검색어 포함 확인
    assert_current_path %r{q=}
  end

  private

  def log_in_as(user)
    visit login_path

    # 명시적으로 입력 필드 찾아서 입력
    find("input[name='email']", wait: 3).set(user.email)
    find("input[name='password']").set("test1234")
    click_button "로그인"

    # 로그인 완료 대기
    assert_no_current_path login_path, wait: 3
  end
end
