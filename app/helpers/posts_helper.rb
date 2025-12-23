module PostsHelper
  # 게시글 카테고리 라벨
  def post_category_label(post)
    Post::CATEGORY_LABELS[post.category] || post.category
  end

  # 게시글 카테고리 배경색 클래스
  def post_category_bg_class(post)
    case post.category
    when "hiring"
      "bg-blue-100"
    when "seeking"
      "bg-purple-100"
    when "free"
      "bg-gray-100"
    when "question"
      "bg-orange-100"
    when "promotion"
      "bg-green-100"
    else
      "bg-gray-100"
    end
  end

  # 게시글 카테고리 뱃지 클래스
  def post_category_badge_class(post)
    case post.category
    when "hiring"
      "bg-blue-100 text-blue-700"
    when "seeking"
      "bg-purple-100 text-purple-700"
    when "free"
      "bg-gray-100 text-gray-700"
    when "question"
      "bg-orange-100 text-orange-700"
    when "promotion"
      "bg-green-100 text-green-700"
    else
      "bg-gray-100 text-gray-700"
    end
  end

  # 게시글 카테고리 아이콘
  def post_category_icon(post)
    case post.category
    when "hiring"
      content_tag(:svg, class: "w-5 h-5 text-blue-600", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        content_tag(:path, nil, stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z")
      end
    when "seeking"
      content_tag(:svg, class: "w-5 h-5 text-purple-600", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        content_tag(:path, nil, stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z")
      end
    when "question"
      content_tag(:svg, class: "w-5 h-5 text-orange-600", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        content_tag(:path, nil, stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z")
      end
    when "promotion"
      content_tag(:svg, class: "w-5 h-5 text-green-600", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        content_tag(:path, nil, stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z")
      end
    else
      content_tag(:svg, class: "w-5 h-5 text-gray-600", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
        content_tag(:path, nil, stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z")
      end
    end
  end
end
