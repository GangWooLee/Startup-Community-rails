# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper
  include ERB::Util  # For h() method

  # ============================================================================
  # Setup
  # ============================================================================

  def setup
    @user = users(:one)
    @user_with_avatar_url = users(:oauth_user)
    @deleted_user = users(:deleted_user)

    # Default controller context for tests
    @test_controller_name = "posts"
    @test_action_name = "index"
    @test_controller_path = "posts"
  end

  # Override controller_name for show_global_sidebar? tests
  def controller_name
    @test_controller_name
  end

  # Override action_name for show_global_sidebar? tests
  def action_name
    @test_action_name
  end

  # Override controller_path for show_global_sidebar? tests
  def controller_path
    @test_controller_path
  end

  # ============================================================================
  # payment_enabled? Tests
  # ============================================================================

  test "payment_enabled? returns false by default" do
    assert_not payment_enabled?
  end

  # ============================================================================
  # og_meta_tags Tests
  # ============================================================================

  test "og_meta_tags returns default values when no options provided" do
    # Mock request object
    controller.request.path = "/"

    result = og_meta_tags

    assert_includes result, 'property="og:title"'
    assert_includes result, 'content="Undrew - 창업자 커뮤니티"'
    assert_includes result, 'property="og:description"'
    assert_includes result, "아이디어·사람·외주가 한 공간에서 연결되는 최초의 창업 커뮤니티"
    assert_includes result, 'property="og:type"'
    assert_includes result, 'content="website"'
    assert_includes result, 'property="og:site_name"'
    assert_includes result, 'content="Undrew"'
    assert_includes result, 'property="og:locale"'
    assert_includes result, 'content="ko_KR"'
    assert_includes result, 'name="twitter:card"'
    assert_includes result, 'content="summary"'
  end

  test "og_meta_tags accepts custom title" do
    result = og_meta_tags(title: "Custom Title")

    assert_includes result, 'property="og:title"'
    assert_includes result, 'content="Custom Title"'
    assert_includes result, 'name="twitter:title"'
    assert_includes result, 'content="Custom Title"'
  end

  test "og_meta_tags accepts custom description" do
    result = og_meta_tags(description: "Custom description text")

    assert_includes result, 'property="og:description"'
    assert_includes result, 'content="Custom description text"'
    assert_includes result, 'name="twitter:description"'
    assert_includes result, 'content="Custom description text"'
  end

  test "og_meta_tags accepts custom type" do
    result = og_meta_tags(type: "article")

    assert_includes result, 'property="og:type"'
    assert_includes result, 'content="article"'
  end

  test "og_meta_tags includes image tags when image provided" do
    result = og_meta_tags(image: "https://example.com/image.jpg")

    assert_includes result, 'property="og:image"'
    assert_includes result, 'content="https://example.com/image.jpg"'
    assert_includes result, 'property="og:image:width"'
    assert_includes result, 'content="1200"'
    assert_includes result, 'property="og:image:height"'
    assert_includes result, 'content="630"'
    assert_includes result, 'name="twitter:card"'
    assert_includes result, 'content="summary_large_image"'
    assert_includes result, 'name="twitter:image"'
  end

  test "og_meta_tags uses summary twitter card when no image" do
    result = og_meta_tags

    assert_includes result, 'name="twitter:card"'
    assert_includes result, 'content="summary"'
    assert_not_includes result, 'name="twitter:image"'
  end

  test "og_meta_tags handles Korean text correctly" do
    result = og_meta_tags(
      title: "한글 제목 테스트",
      description: "한글 설명 테스트입니다"
    )

    assert_includes result, "한글 제목 테스트"
    assert_includes result, "한글 설명 테스트입니다"
  end

  test "og_meta_tags returns html_safe string" do
    result = og_meta_tags
    assert result.html_safe?
  end

  # ============================================================================
  # highlight_search Tests
  # ============================================================================

  test "highlight_search returns empty string for blank text" do
    assert_equal "", highlight_search("", "query")
    assert_equal "", highlight_search(nil, "query")
  end

  test "highlight_search returns escaped text for blank query" do
    result = highlight_search("Hello World", "")
    assert_equal "Hello World", result

    result = highlight_search("Hello World", nil)
    assert_equal "Hello World", result
  end

  test "highlight_search wraps matching text in mark tag" do
    result = highlight_search("Hello World", "World")

    assert_includes result, '<mark class="bg-yellow-200 text-foreground px-0.5 rounded">World</mark>'
  end

  test "highlight_search is case insensitive" do
    result = highlight_search("Hello WORLD", "world")

    assert_includes result, '<mark class="bg-yellow-200 text-foreground px-0.5 rounded">WORLD</mark>'
  end

  test "highlight_search highlights multiple occurrences" do
    result = highlight_search("test test test", "test")

    # Count the number of mark tags
    mark_count = result.scan(/<mark/).count
    assert_equal 3, mark_count
  end

  test "highlight_search escapes HTML in text" do
    result = highlight_search("<script>alert('xss')</script>", "alert")

    # Verify the script tags are escaped (not raw HTML)
    assert_not_includes result, "<script>"
    assert_includes result, "&lt;script&gt;"
    # The search term should still be highlighted
    assert_includes result, '<mark class="bg-yellow-200 text-foreground px-0.5 rounded">alert</mark>'
  end

  test "highlight_search handles special regex characters in query" do
    result = highlight_search("test (value) test", "(value)")

    assert_includes result, '<mark class="bg-yellow-200 text-foreground px-0.5 rounded">(value)</mark>'
  end

  test "highlight_search returns html_safe string" do
    result = highlight_search("Hello World", "World")
    assert result.html_safe?
  end

  # ============================================================================
  # highlight_snippet Tests
  # ============================================================================

  test "highlight_snippet returns empty string for blank text" do
    assert_equal "", highlight_snippet("", "query")
    assert_equal "", highlight_snippet(nil, "query")
  end

  test "highlight_snippet truncates text when query is blank" do
    long_text = "a" * 200
    result = highlight_snippet(long_text, "")

    assert_operator result.length, :<=, 103  # 100 + "..."
  end

  test "highlight_snippet shows context around query match" do
    text = "This is a long text with the keyword somewhere in the middle of the content"
    result = highlight_snippet(text, "keyword")

    assert_includes result, "keyword"
    assert_includes result, '<mark class="bg-yellow-200 text-foreground px-0.5 rounded">keyword</mark>'
  end

  test "highlight_snippet adds ellipsis when truncating from start" do
    text = "a" * 50 + "keyword" + "b" * 50
    result = highlight_snippet(text, "keyword")

    assert result.start_with?("...")
  end

  test "highlight_snippet adds ellipsis when truncating from end" do
    text = "keyword" + "a" * 200
    result = highlight_snippet(text, "keyword")

    assert result.end_with?("...")
  end

  test "highlight_snippet respects max_length parameter" do
    text = "a" * 300
    result = highlight_snippet(text, "", max_length: 50)

    # The result should be truncated to approximately max_length
    assert_operator result.length, :<=, 53  # 50 + "..."
  end

  test "highlight_snippet falls back to truncation when query not found" do
    text = "This is some text without the search term"
    result = highlight_snippet(text, "notfound", max_length: 20)

    assert_operator result.length, :<=, 23  # 20 + "..."
  end

  # ============================================================================
  # pagination_range Tests
  # ============================================================================

  test "pagination_range returns empty array for zero pages" do
    assert_equal [], pagination_range(1, 0)
  end

  test "pagination_range returns empty array for negative pages" do
    assert_equal [], pagination_range(1, -1)
  end

  test "pagination_range returns single page for total_pages of 1" do
    assert_equal [ 1 ], pagination_range(1, 1)
  end

  test "pagination_range returns all pages when total_pages <= 5" do
    assert_equal [ 1, 2, 3 ], pagination_range(1, 3)
    assert_equal [ 1, 2, 3, 4, 5 ], pagination_range(3, 5)
  end

  test "pagination_range shows first pages with ellipsis when current page is at start" do
    result = pagination_range(1, 10)

    assert_equal 1, result.first
    assert_equal 10, result.last
    assert_includes result, :ellipsis
    assert_includes result, 2
    assert_includes result, 3
    assert_includes result, 4
  end

  test "pagination_range shows last pages with ellipsis when current page is at end" do
    result = pagination_range(10, 10)

    assert_equal 1, result.first
    assert_equal 10, result.last
    assert_includes result, :ellipsis
    assert_includes result, 7
    assert_includes result, 8
    assert_includes result, 9
  end

  test "pagination_range shows middle pages with ellipsis when current page is in middle" do
    result = pagination_range(5, 10)

    assert_equal 1, result.first
    assert_equal 10, result.last
    # Should include current page and neighbors
    assert_includes result, 4
    assert_includes result, 5
    assert_includes result, 6
    # Should have at least one ellipsis
    assert_includes result, :ellipsis
  end

  test "pagination_range for page 3 on 10 pages" do
    result = pagination_range(3, 10)

    assert_equal 1, result.first
    assert_equal 10, result.last
    assert_includes result, 2
    assert_includes result, 3
    assert_includes result, 4
  end

  test "pagination_range for page 8 on 10 pages" do
    result = pagination_range(8, 10)

    assert_equal 1, result.first
    assert_equal 10, result.last
    assert_includes result, :ellipsis
    assert_includes result, 7
    assert_includes result, 8
    assert_includes result, 9
  end

  # ============================================================================
  # avatar_bg_color Tests
  # ============================================================================

  test "avatar_bg_color returns default gray for blank name" do
    assert_equal "bg-gray-400", avatar_bg_color("")
    assert_equal "bg-gray-400", avatar_bg_color(nil)
  end

  test "avatar_bg_color returns consistent color for same name" do
    color1 = avatar_bg_color("Alice")
    color2 = avatar_bg_color("Alice")

    assert_equal color1, color2
  end

  test "avatar_bg_color returns different colors for different names" do
    colors = %w[Alice Bob Carol Dave].map { |name| avatar_bg_color(name) }

    # Not all should be the same (though theoretically possible)
    assert colors.uniq.length > 1
  end

  test "avatar_bg_color returns valid Tailwind bg class" do
    color = avatar_bg_color("Test")

    assert_match(/^bg-\w+-500$/, color)
  end

  test "avatar_bg_color handles Korean names" do
    color = avatar_bg_color("홍길동")

    assert_match(/^bg-\w+-500$/, color)
  end

  # ============================================================================
  # message_preview Tests
  # ============================================================================

  test "message_preview returns truncated content for regular messages" do
    message = Message.new(message_type: "text", content: "a" * 50)
    result = message_preview(message)

    assert_operator result.length, :<=, 30
  end

  test "message_preview returns truncated content for system messages" do
    message = Message.new(message_type: "system", content: "System notification message")
    result = message_preview(message)

    assert_operator result.length, :<=, 30
  end

  test "message_preview returns special text for deal_confirm" do
    message = Message.new(message_type: "deal_confirm", content: "")
    result = message_preview(message)

    assert_equal "거래가 확정되었습니다", result
  end

  test "message_preview returns special text for profile_card" do
    message = Message.new(message_type: "profile_card", content: "")
    result = message_preview(message)

    assert_equal "프로필을 공유했습니다", result
  end

  test "message_preview returns special text for contact_card" do
    message = Message.new(message_type: "contact_card", content: "")
    result = message_preview(message)

    assert_equal "연락처를 공유했습니다", result
  end

  # ============================================================================
  # render_user_avatar Tests
  # ============================================================================

  test "render_user_avatar returns empty string for nil user" do
    assert_equal "", render_user_avatar(nil)
  end

  test "render_user_avatar renders fallback with initial for user without avatar" do
    result = render_user_avatar(@user)

    assert_includes result, @user.name.first.upcase
    assert_includes result, "rounded-full"
  end

  test "render_user_avatar uses default md size" do
    result = render_user_avatar(@user)

    assert_includes result, "h-10"
    assert_includes result, "w-10"
  end

  test "render_user_avatar accepts xs size" do
    result = render_user_avatar(@user, size: "xs")

    assert_includes result, "h-5"
    assert_includes result, "w-5"
  end

  test "render_user_avatar accepts sm size" do
    result = render_user_avatar(@user, size: "sm")

    assert_includes result, "h-8"
    assert_includes result, "w-8"
  end

  test "render_user_avatar accepts lg size" do
    result = render_user_avatar(@user, size: "lg")

    assert_includes result, "h-12"
    assert_includes result, "w-12"
  end

  test "render_user_avatar accepts xl size" do
    result = render_user_avatar(@user, size: "xl")

    assert_includes result, "h-16"
    assert_includes result, "w-16"
  end

  test "render_user_avatar accepts 2xl size" do
    result = render_user_avatar(@user, size: "2xl")

    assert_includes result, "h-20"
    assert_includes result, "w-20"
  end

  test "render_user_avatar falls back to md for invalid size" do
    result = render_user_avatar(@user, size: "invalid")

    assert_includes result, "h-10"
    assert_includes result, "w-10"
  end

  test "render_user_avatar adds extra class" do
    result = render_user_avatar(@user, class: "shadow-lg custom-class")

    assert_includes result, "shadow-lg"
    assert_includes result, "custom-class"
  end

  test "render_user_avatar adds ring class" do
    result = render_user_avatar(@user, ring: "ring-2 ring-background")

    assert_includes result, "ring-2"
    assert_includes result, "ring-background"
  end

  test "render_user_avatar uses custom fallback_bg" do
    result = render_user_avatar(@user, fallback_bg: "bg-primary")

    assert_includes result, "bg-primary"
  end

  test "render_user_avatar uses custom fallback_text_color" do
    result = render_user_avatar(@user, fallback_text_color: "text-white")

    assert_includes result, "text-white"
  end

  test "render_user_avatar renders image for user with avatar_url" do
    result = render_user_avatar(@user_with_avatar_url)

    assert_includes result, "<img"
    assert_includes result, @user_with_avatar_url.avatar_url
  end

  test "render_user_avatar shows question mark for user with blank name" do
    user = User.new(name: nil)
    result = render_user_avatar(user)

    assert_includes result, "?"
  end

  test "render_user_avatar returns html_safe string" do
    result = render_user_avatar(@user)
    assert result.html_safe?
  end

  # ============================================================================
  # safe_url? Tests
  # ============================================================================

  test "safe_url? returns false for blank url" do
    assert_not safe_url?("")
    assert_not safe_url?(nil)
  end

  test "safe_url? returns true for http urls" do
    assert safe_url?("http://example.com")
    assert safe_url?("http://example.com/path")
  end

  test "safe_url? returns true for https urls" do
    assert safe_url?("https://example.com")
    assert safe_url?("https://example.com/path?query=1")
  end

  test "safe_url? returns false for javascript urls" do
    assert_not safe_url?("javascript:alert('xss')")
    assert_not safe_url?("JavaScript:void(0)")
  end

  test "safe_url? returns false for data urls" do
    assert_not safe_url?("data:text/html,<script>alert('xss')</script>")
  end

  test "safe_url? returns false for invalid urls" do
    assert_not safe_url?("not a valid url")
    assert_not safe_url?("://invalid")
  end

  test "safe_url? returns false for urls without scheme" do
    assert_not safe_url?("example.com")
    assert_not safe_url?("/path/to/page")
  end

  test "safe_url? returns false for ftp urls" do
    assert_not safe_url?("ftp://example.com/file")
  end

  test "safe_url? returns false for file urls" do
    assert_not safe_url?("file:///etc/passwd")
  end

  # ============================================================================
  # show_global_sidebar? Tests
  # ============================================================================

  test "show_global_sidebar? returns false for sessions controller" do
    @test_controller_name = "sessions"
    @test_action_name = "new"
    @test_controller_path = "sessions"

    assert_not show_global_sidebar?
  end

  test "show_global_sidebar? returns false for registrations controller" do
    @test_controller_name = "registrations"
    @test_action_name = "new"
    @test_controller_path = "registrations"

    assert_not show_global_sidebar?
  end

  test "show_global_sidebar? returns false for passwords controller" do
    @test_controller_name = "passwords"
    @test_action_name = "new"
    @test_controller_path = "passwords"

    assert_not show_global_sidebar?
  end

  test "show_global_sidebar? returns false for onboarding landing page" do
    @test_controller_name = "onboarding"
    @test_action_name = "landing"
    @test_controller_path = "onboarding"

    assert_not show_global_sidebar?
  end

  test "show_global_sidebar? returns false for admin pages" do
    @test_controller_name = "users"
    @test_action_name = "index"
    @test_controller_path = "admin/users"

    assert_not show_global_sidebar?
  end

  test "show_global_sidebar? returns true for posts controller" do
    @test_controller_name = "posts"
    @test_action_name = "index"
    @test_controller_path = "posts"

    assert show_global_sidebar?
  end

  test "show_global_sidebar? returns true for onboarding ai_input page" do
    @test_controller_name = "onboarding"
    @test_action_name = "ai_input"
    @test_controller_path = "onboarding"

    assert show_global_sidebar?
  end

  # ============================================================================
  # sidebar_icon Tests
  # ============================================================================

  test "sidebar_icon renders svg element" do
    result = sidebar_icon(:home)

    assert_includes result, "<svg"
    assert_includes result, "</svg>"
    assert_includes result, 'viewBox="0 0 24 24"'
  end

  test "sidebar_icon renders correct path for home icon" do
    result = sidebar_icon(:home)

    assert_includes result, "M3 12l2-2"
  end

  test "sidebar_icon renders correct path for chat icon" do
    result = sidebar_icon(:chat)

    assert_includes result, "M8 12h.01M12 12h.01M16 12h.01"
  end

  test "sidebar_icon renders correct path for ai icon" do
    result = sidebar_icon(:ai)

    assert_includes result, "M9.663 17h4.673"
  end

  test "sidebar_icon applies active styling" do
    result = sidebar_icon(:home, active: true)

    assert_includes result, "text-orange-500"
    assert_includes result, 'stroke-width="0"'
    assert_includes result, 'fill="currentColor"'
  end

  test "sidebar_icon applies inactive styling" do
    result = sidebar_icon(:home, active: false)

    assert_not_includes result, "text-orange-500"
    assert_includes result, 'stroke-width="2"'
    assert_includes result, 'fill="none"'
  end

  test "sidebar_icon falls back to home icon for unknown name" do
    result = sidebar_icon(:unknown_icon)

    # Should render home icon path as fallback
    assert_includes result, "M3 12l2-2"
  end

  test "sidebar_icon returns html_safe string" do
    result = sidebar_icon(:home)
    assert result.html_safe?
  end

  # ============================================================================
  # sidebar_nav_item Tests
  # ============================================================================

  test "sidebar_nav_item renders link with label" do
    result = sidebar_nav_item("Home", "/", :home, is_active: false)

    assert_includes result, "Home"
    assert_includes result, 'href="/"'
  end

  test "sidebar_nav_item applies active class when current page" do
    result = sidebar_nav_item("Home", "/", :home, is_active: true)

    assert_includes result, "text-stone-900"
    assert_includes result, "bg-white"
    assert_includes result, "font-bold"
  end

  test "sidebar_nav_item applies inactive class when not current page" do
    result = sidebar_nav_item("Home", "/", :home, is_active: false)

    assert_includes result, "text-stone-600"
    assert_includes result, "hover:bg-stone-50"
  end

  test "sidebar_nav_item shows badge when provided" do
    result = sidebar_nav_item("Chat", "/chat", :chat, badge: 5, is_active: false)

    assert_includes result, "5"
    assert_includes result, "bg-red-500"
    assert_includes result, "rounded-full"
  end

  test "sidebar_nav_item shows 99+ for large badge count" do
    result = sidebar_nav_item("Chat", "/chat", :chat, badge: 150, is_active: false)

    assert_includes result, "99+"
  end

  test "sidebar_nav_item does not show badge for zero" do
    result = sidebar_nav_item("Chat", "/chat", :chat, badge: 0, is_active: false)

    assert_not_includes result, "bg-red-500"
  end

  test "sidebar_nav_item applies small size class" do
    result = sidebar_nav_item("Home", "/", :home, size: :sm, is_active: false)

    assert_includes result, "text-sm"
  end

  # ============================================================================
  # collapsible_sidebar_nav_item Tests
  # ============================================================================

  test "collapsible_sidebar_nav_item renders expanded and collapsed versions" do
    result = collapsible_sidebar_nav_item("Home", "/", :home, is_active: false)

    # Should contain both data targets
    assert_includes result, 'data-sidebar-collapse-target="expandedContent"'
    assert_includes result, 'data-sidebar-collapse-target="collapsedContent"'
  end

  test "collapsible_sidebar_nav_item shows label in expanded version" do
    result = collapsible_sidebar_nav_item("Home", "/", :home, is_active: false)

    assert_includes result, "Home"
  end

  test "collapsible_sidebar_nav_item shows badge in both versions when provided" do
    result = collapsible_sidebar_nav_item("Chat", "/chat", :chat, badge: 10, is_active: false)

    # Expanded version shows number
    assert_includes result, "10"
    # Collapsed version shows dot indicator
    assert_includes result, "w-2.5 h-2.5 bg-red-500 rounded-full"
  end

  test "collapsible_sidebar_nav_item applies active styling" do
    result = collapsible_sidebar_nav_item("Home", "/", :home, is_active: true)

    assert_includes result, "text-stone-900"
    assert_includes result, "bg-stone-100"
    assert_includes result, "font-bold"
  end

  test "collapsible_sidebar_nav_item applies inactive styling" do
    result = collapsible_sidebar_nav_item("Home", "/", :home, is_active: false)

    assert_includes result, "text-stone-600"
    assert_includes result, "hover:bg-stone-50"
  end

  test "collapsible_sidebar_nav_item has title attribute for tooltip" do
    result = collapsible_sidebar_nav_item("Home Page", "/", :home, is_active: false)

    assert_includes result, 'title="Home Page"'
  end

  test "collapsible_sidebar_nav_item returns html_safe string" do
    result = collapsible_sidebar_nav_item("Home", "/", :home, is_active: false)
    assert result.html_safe?
  end

  # =============================================================================
  # linkify_urls Tests (URL 자동 하이퍼링크 변환)
  # =============================================================================

  # ----- 기본 동작 -----
  test "linkify_urls returns empty string for blank text" do
    assert_equal "", linkify_urls("")
    assert_equal "", linkify_urls(nil)
  end

  test "linkify_urls returns html_safe string" do
    result = linkify_urls("Hello")
    assert result.html_safe?
  end

  test "linkify_urls leaves plain text unchanged" do
    result = linkify_urls("일반 텍스트입니다")
    assert_equal "일반 텍스트입니다", result
  end

  # ----- URL 변환 -----
  test "linkify_urls converts https URL to link" do
    result = linkify_urls("Visit https://google.com today")

    # 속성 순서는 다를 수 있으므로 개별 속성으로 검증
    assert_includes result, 'href="https://google.com"'
    assert_includes result, 'target="_blank"'
    assert_includes result, 'rel="noopener noreferrer"'
    assert_includes result, "<a "  # 링크 태그 존재 확인
  end

  test "linkify_urls converts http URL to link" do
    result = linkify_urls("Check http://example.com/path?q=1")

    assert_includes result, 'href="http://example.com/path?q=1"'
  end

  test "linkify_urls converts www URL to link" do
    result = linkify_urls("Visit www.naver.com")

    # rails_autolink은 www URL을 http://로 변환
    assert_includes result, 'href="http://www.naver.com"'
  end

  test "linkify_urls converts multiple URLs" do
    text = "Visit https://a.com and https://b.com"
    result = linkify_urls(text)

    assert_includes result, 'href="https://a.com"'
    assert_includes result, 'href="https://b.com"'
  end

  # ----- 보안 (XSS 방지) -----
  test "linkify_urls removes dangerous HTML tags" do
    result = linkify_urls("<script>alert('xss')</script>")

    # sanitize는 <script> 태그를 완전히 제거함 (더 안전한 동작)
    assert_not_includes result, "<script>"
    assert_not_includes result, "</script>"
    # 태그 내용만 남음
    assert_equal "alert('xss')", result
  end

  test "linkify_urls does not convert javascript URLs" do
    result = linkify_urls("javascript:alert(1)")

    assert_not_includes result, '<a href="javascript:'
  end

  # ----- 링크 속성 -----
  test "linkify_urls adds target blank" do
    result = linkify_urls("https://example.com")

    assert_includes result, 'target="_blank"'
  end

  test "linkify_urls adds rel noopener noreferrer" do
    result = linkify_urls("https://example.com")

    assert_includes result, 'rel="noopener noreferrer"'
  end

  test "linkify_urls adds styling class" do
    result = linkify_urls("https://example.com")

    assert_includes result, 'class="text-primary hover:underline break-all"'
  end
end
