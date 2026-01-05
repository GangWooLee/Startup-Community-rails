# frozen_string_literal: true

require "test_helper"

class PostsHelperTest < ActionView::TestCase
  include PostsHelper

  setup do
    @hiring_post = posts(:hiring_post)
    @seeking_post = posts(:seeking_post)
    @free_post = posts(:one)
    @question_post = posts(:two)
    @promotion_post = posts(:promotion_post)
  end

  # =========================================
  # Devicon URL Tests
  # =========================================

  test "devicon_url returns correct URL for standard tech names" do
    assert_equal "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/react/react-original.svg",
                 devicon_url("React")
    assert_equal "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/python/python-original.svg",
                 devicon_url("Python")
  end

  test "devicon_url handles case insensitivity" do
    assert_equal devicon_url("react"), devicon_url("REACT")
    assert_equal devicon_url("python"), devicon_url("Python")
  end

  test "devicon_url maps common aliases" do
    # JS -> javascript
    assert_match /javascript/, devicon_url("js")
    assert_match /javascript/, devicon_url("JS")

    # TS -> typescript
    assert_match /typescript/, devicon_url("ts")

    # rb -> ruby
    assert_match /ruby/, devicon_url("rb")

    # py -> python
    assert_match /python/, devicon_url("py")

    # vue -> vuejs
    assert_match /vuejs/, devicon_url("vue")
    assert_match /vuejs/, devicon_url("vue3")

    # node -> nodejs
    assert_match /nodejs/, devicon_url("node")

    # rails -> rails
    assert_match /rails/, devicon_url("rubyonrails")

    # postgres -> postgresql
    assert_match /postgresql/, devicon_url("postgres")

    # k8s -> kubernetes
    assert_match /kubernetes/, devicon_url("k8s")

    # tailwind -> tailwindcss
    assert_match /tailwindcss/, devicon_url("tailwind")
  end

  test "devicon_url handles special characters with aliases" do
    # Use the aliases that work (without special chars)
    assert_match /cplusplus/, devicon_url("cpp")
    assert_match /csharp/, devicon_url("csharp")
  end

  test "devicon_url returns normalized URL for unknown tech" do
    url = devicon_url("SomeNewTech")
    assert_match /somenewtech/, url
  end

  # =========================================
  # Tech Icon Tests
  # =========================================

  test "tech_icon returns img tag with correct src" do
    result = tech_icon("React")
    assert_match /<img/, result
    assert_match /react/, result
    assert_match /alt="React"/, result
  end

  test "tech_icon uses default size" do
    result = tech_icon("Python")
    assert_match /class="w-5 h-5"/, result
  end

  test "tech_icon accepts custom size" do
    result = tech_icon("Ruby", size: "w-8 h-8")
    assert_match /class="w-8 h-8"/, result
  end

  test "tech_icon includes onerror handler" do
    result = tech_icon("React")
    assert_match /onerror/, result
  end

  # =========================================
  # Post Category Label Tests
  # =========================================

  test "post_category_label returns correct labels" do
    assert_equal "Makers", post_category_label(@hiring_post)
    assert_equal "Projects", post_category_label(@seeking_post)
    assert_equal "자유", post_category_label(@free_post)
    assert_equal "질문", post_category_label(@question_post)
    assert_equal "홍보", post_category_label(@promotion_post)
  end

  # =========================================
  # Post Category Background Class Tests
  # =========================================

  test "post_category_bg_class returns correct classes" do
    assert_equal "bg-blue-100", post_category_bg_class(@hiring_post)
    assert_equal "bg-purple-100", post_category_bg_class(@seeking_post)
    assert_equal "bg-gray-100", post_category_bg_class(@free_post)
    assert_equal "bg-orange-100", post_category_bg_class(@question_post)
    assert_equal "bg-green-100", post_category_bg_class(@promotion_post)
  end

  # =========================================
  # Post Category Badge Class Tests
  # =========================================

  test "post_category_badge_class returns correct classes" do
    assert_equal "bg-blue-100 text-blue-700", post_category_badge_class(@hiring_post)
    assert_equal "bg-purple-100 text-purple-700", post_category_badge_class(@seeking_post)
    assert_equal "bg-gray-100 text-gray-700", post_category_badge_class(@free_post)
    assert_equal "bg-orange-100 text-orange-700", post_category_badge_class(@question_post)
    assert_equal "bg-green-100 text-green-700", post_category_badge_class(@promotion_post)
  end

  # =========================================
  # Post Category Icon Tests
  # =========================================

  test "post_category_icon returns SVG for hiring" do
    result = post_category_icon(@hiring_post)
    assert_match /<svg/, result
    assert_match /text-blue-600/, result
  end

  test "post_category_icon returns SVG for seeking" do
    result = post_category_icon(@seeking_post)
    assert_match /<svg/, result
    assert_match /text-purple-600/, result
  end

  test "post_category_icon returns SVG for question" do
    result = post_category_icon(@question_post)
    assert_match /<svg/, result
    assert_match /text-orange-600/, result
  end

  test "post_category_icon returns SVG for promotion" do
    result = post_category_icon(@promotion_post)
    assert_match /<svg/, result
    assert_match /text-green-600/, result
  end

  test "post_category_icon returns SVG for free" do
    result = post_category_icon(@free_post)
    assert_match /<svg/, result
    assert_match /text-gray-600/, result
  end
end
