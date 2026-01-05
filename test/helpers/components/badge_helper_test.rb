# frozen_string_literal: true

require "test_helper"

class Components::BadgeHelperTest < ActionView::TestCase
  include Components::BadgeHelper
  include ComponentsHelper

  # =========================================
  # Basic Rendering Tests
  # =========================================

  test "render_badge returns a div element" do
    result = render_badge("Test Badge")
    assert_match /<div/, result
    assert_match /Test Badge/, result
  end

  test "render_badge with empty label" do
    result = render_badge("")
    assert_match /<div/, result
  end

  test "render_badge uses text parameter" do
    result = render_badge(text: "Custom Text")
    assert_match /Custom Text/, result
  end

  test "render_badge label overrides text" do
    result = render_badge("Label Text", text: "Should be ignored")
    assert_match /Label Text/, result
    assert_no_match /Should be ignored/, result
  end

  # =========================================
  # Variant Tests
  # =========================================

  test "render_badge with default variant" do
    result = render_badge("Default", variant: :default)
    assert_match /<div/, result
    # Should include primary classes
    assert_match /bg-primary/, result
  end

  test "render_badge with secondary variant" do
    result = render_badge("Secondary", variant: :secondary)
    assert_match /bg-secondary/, result
  end

  test "render_badge with destructive variants" do
    [:error, :danger, :alert, :destructive].each do |variant|
      result = render_badge("Error", variant: variant)
      assert_match /bg-destructive/, result, "Expected destructive class for #{variant}"
    end
  end

  test "render_badge with outline variant" do
    result = render_badge("Outline", variant: :outline)
    assert_match /border/, result
  end

  test "render_badge with ghost variant" do
    result = render_badge("Ghost", variant: :ghost)
    assert_match /hover:bg-accent/, result
  end

  # =========================================
  # CSS Classes Tests
  # =========================================

  test "render_badge includes base classes" do
    result = render_badge("Test")
    assert_match /inline-flex/, result
    assert_match /items-center/, result
    assert_match /rounded-full/, result
    assert_match /text-xs/, result
    assert_match /font-semibold/, result
  end

  # =========================================
  # Edge Cases
  # =========================================

  test "render_badge with string variant" do
    result = render_badge("Test", variant: "secondary")
    assert_match /bg-secondary/, result
  end

  test "render_badge with special characters" do
    result = render_badge("<script>alert('xss')</script>")
    # Should be escaped
    assert_no_match /<script>/, result
  end

  test "render_badge with unicode text" do
    result = render_badge("한글 뱃지")
    assert_match /한글 뱃지/, result
  end
end
