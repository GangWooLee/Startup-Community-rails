# frozen_string_literal: true

require "test_helper"

class ProfilesHelperTest < ActionView::TestCase
  include ProfilesHelper

  # =========================================
  # privacy_blur_wrapper
  # =========================================

  test "privacy_blur_wrapper returns content directly when visible is true" do
    result = privacy_blur_wrapper(visible: true) { "<div>Test Content</div>".html_safe }

    assert_includes result, "Test Content"
    assert_not_includes result, "blur-sm"
    assert_not_includes result, "익명 사용자입니다"
  end

  test "privacy_blur_wrapper wraps content with blur when visible is false" do
    result = privacy_blur_wrapper(visible: false) { "<div>Test Content</div>".html_safe }

    assert_includes result, "Test Content"
    assert_includes result, "blur-sm"
    assert_includes result, "pointer-events-none"
    assert_includes result, "익명 사용자입니다"
  end

  test "privacy_blur_wrapper shows lock icon when blurred" do
    result = privacy_blur_wrapper(visible: false) { "<div>Content</div>".html_safe }

    # Lock icon SVG path
    assert_includes result, "M12 15v2m-6 4h12"
    assert_includes result, "bg-secondary"
  end

  test "privacy_blur_wrapper uses custom message when provided" do
    custom_message = "이 섹션은 비공개입니다"
    result = privacy_blur_wrapper(visible: false, message: custom_message) do
      "<div>Content</div>".html_safe
    end

    assert_includes result, custom_message
    assert_not_includes result, "익명 사용자입니다"
  end

  test "privacy_blur_wrapper has proper accessibility structure" do
    result = privacy_blur_wrapper(visible: false) { "<div>Content</div>".html_safe }

    # 블러 콘텐츠에 select-none 포함 (복사 방지)
    assert_includes result, "select-none"
    # 오버레이에 flex items-center justify-center (중앙 정렬)
    assert_includes result, "flex items-center justify-center"
  end

  test "privacy_blur_wrapper supports dark mode" do
    result = privacy_blur_wrapper(visible: false) { "<div>Content</div>".html_safe }

    # dark mode 스타일 포함
    assert_includes result, "dark:bg-gray-900/70"
  end

  test "privacy_blur_wrapper preserves complex block content" do
    complex_content = <<~HTML.html_safe
      <section class="card">
        <h2>Title</h2>
        <p>Description</p>
        <ul>
          <li>Item 1</li>
          <li>Item 2</li>
        </ul>
      </section>
    HTML

    result = privacy_blur_wrapper(visible: false) { complex_content }

    assert_includes result, "<h2>Title</h2>"
    assert_includes result, "<li>Item 1</li>"
    assert_includes result, "blur-sm"
  end
end
