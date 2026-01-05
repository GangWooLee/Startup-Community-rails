module PostsHelper
  # ===== Tech Stack Icon Helpers =====

  # Devicon CDN URL 생성 (기술 스택 아이콘용)
  # @param skill_name [String] 기술명 (e.g., "React", "Ruby", "Python")
  # @return [String] Devicon SVG URL
  # @example devicon_url("React") => "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/react/react-original.svg"
  def devicon_url(skill_name)
    # 기술명 정규화: 소문자 + 특수문자 제거
    normalized = skill_name.to_s.downcase.strip.gsub(/[^a-z0-9]/, "")

    # 기술명 매핑 (특수 케이스 처리)
    mapping = {
      "js" => "javascript",
      "ts" => "typescript",
      "rb" => "ruby",
      "py" => "python",
      "cpp" => "cplusplus",
      "c++" => "cplusplus",
      "c#" => "csharp",
      "csharp" => "csharp",
      "objc" => "objectivec",
      "objectivec" => "objectivec",
      "golang" => "go",
      "vue" => "vuejs",
      "vuejs" => "vuejs",
      "vue3" => "vuejs",
      "nextjs" => "nextjs",
      "next" => "nextjs",
      "nuxt" => "nuxtjs",
      "nuxtjs" => "nuxtjs",
      "expressjs" => "express",
      "express" => "express",
      "nodejs" => "nodejs",
      "node" => "nodejs",
      "reactnative" => "react",
      "rails" => "rails",
      "rubyonrails" => "rails",
      "postgresql" => "postgresql",
      "postgres" => "postgresql",
      "mysql" => "mysql",
      "mongodb" => "mongodb",
      "mongo" => "mongodb",
      "redis" => "redis",
      "docker" => "docker",
      "kubernetes" => "kubernetes",
      "k8s" => "kubernetes",
      "aws" => "amazonwebservices",
      "gcp" => "googlecloud",
      "azure" => "azure",
      "firebase" => "firebase",
      "tailwindcss" => "tailwindcss",
      "tailwind" => "tailwindcss",
      "sass" => "sass",
      "scss" => "sass",
      "flutter" => "flutter",
      "dart" => "dart",
      "swift" => "swift",
      "kotlin" => "kotlin",
      "java" => "java",
      "spring" => "spring",
      "springboot" => "spring",
      "django" => "django",
      "flask" => "flask",
      "fastapi" => "fastapi",
      "graphql" => "graphql",
      "git" => "git",
      "github" => "github",
      "figma" => "figma",
      "sketch" => "sketch",
      "xd" => "xd",
      "photoshop" => "photoshop",
      "illustrator" => "illustrator"
    }

    # 매핑된 이름 또는 원본 사용
    icon_name = mapping[normalized] || normalized

    "https://cdn.jsdelivr.net/gh/devicons/devicon/icons/#{icon_name}/#{icon_name}-original.svg"
  end

  # 기술 스택 아이콘 렌더링 (fallback 포함)
  # @param skill_name [String] 기술명
  # @param size [String] 아이콘 크기 클래스 (default: "w-5 h-5")
  # @return [String] 이미지 태그 HTML
  def tech_icon(skill_name, size: "w-5 h-5")
    tag.img(
      src: devicon_url(skill_name),
      alt: skill_name,
      class: size,
      onerror: "this.style.display='none'"
    )
  end

  # ===== Category Helpers =====

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
