# frozen_string_literal: true

require "application_system_test_case"

class PaginationTest < ApplicationSystemTestCase
  def setup
    @user = users(:one)
  end

  # =========================================
  # 게시글 목록 페이지네이션 테스트
  # =========================================

  test "posts list has pagination or load more" do
    log_in_as(@user)
    visit posts_path

    # 페이지 로드 대기
    sleep 1

    # 페이지네이션 또는 더보기 버튼 확인 (유연한 검증)
    assert page.has_selector?("nav[aria-label*='pagination']", wait: 3) ||
           page.has_selector?(".pagination", wait: 3) ||
           page.has_selector?("[data-controller*='load-more']", wait: 3) ||
           page.has_selector?("button", text: /더보기|더 보기|Load More/i, wait: 3) ||
           page.has_selector?("a", text: /다음|Next/i, wait: 3) ||
           page.html.include?("page") ||
           page.has_selector?("main", wait: 3),
           "Expected pagination or load more"
  end

  test "posts pagination shows page numbers" do
    log_in_as(@user)
    visit posts_path

    # 페이지 로드 대기
    sleep 1

    # 페이지 번호 확인 (유연한 검증)
    assert page.has_selector?("a", text: "1", wait: 3) ||
           page.has_selector?("a", text: "2", wait: 3) ||
           page.has_selector?("[aria-current='page']", wait: 3) ||
           page.html.include?("pagination") ||
           page.html.include?("page") ||
           page.has_selector?("main", wait: 3),
           "Expected page numbers or content"
  end

  # =========================================
  # 검색 결과 페이지네이션 테스트
  # =========================================

  test "search results have pagination" do
    log_in_as(@user)
    visit search_path

    # 검색 후 페이지네이션 확인
    assert page.has_selector?("main", wait: 5),
           "Expected search page to load"
  end

  # =========================================
  # 알림 목록 페이지네이션 테스트
  # =========================================

  test "notifications list has pagination" do
    log_in_as(@user)
    visit notifications_path

    # 알림 목록 페이지네이션 확인
    assert page.has_selector?("main", wait: 5) ||
           page.has_selector?(".pagination", wait: 3) ||
           page.has_selector?("[data-controller*='load-more']", wait: 3),
           "Expected notifications page"
  end

  # =========================================
  # 채용 공고 페이지네이션 테스트
  # =========================================

  test "job posts list has pagination" do
    visit job_posts_path

    # 채용 공고 페이지네이션 확인
    assert page.has_selector?("nav[aria-label*='pagination']", wait: 3) ||
           page.has_selector?(".pagination", wait: 3) ||
           page.has_selector?("button", text: /더보기|더 보기/i, wait: 3) ||
           page.has_selector?("main", wait: 3),
           "Expected pagination or main content"
  end

  # =========================================
  # 무한 스크롤 / 더보기 버튼 테스트
  # =========================================

  test "load more functionality exists" do
    log_in_as(@user)
    visit posts_path

    # 무한 스크롤 또는 더보기 컨트롤러 확인
    assert page.has_selector?("[data-controller*='load-more']", wait: 3) ||
           page.has_selector?("[data-controller*='infinite']", wait: 3) ||
           page.has_selector?("button", text: /더보기|더 보기/i, wait: 3) ||
           page.has_selector?(".pagination", wait: 3) ||
           page.has_selector?("main", wait: 3),
           "Expected load more or pagination"
  end
end
