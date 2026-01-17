# frozen_string_literal: true

# SEO 헬퍼 - Canonical URL 및 Structured Data (JSON-LD)
#
# SEO 최적화를 위한 헬퍼 메서드 모음
# - Canonical URL 생성 (www vs non-www 정규화)
# - JSON-LD 구조화 데이터 (Organization, WebSite, Article, BreadcrumbList)
module SeoHelper
  CANONICAL_HOST = "undrewai.com"
  CANONICAL_PROTOCOL = "https"

  # ==========================================================================
  # Canonical URL
  # ==========================================================================

  # Canonical URL 생성
  # @param options [Hash] 옵션
  #   :url - 직접 지정 URL (선택)
  #   :params - URL 파라미터 허용 목록 (기본: 없음)
  # @return [String] 정규화된 canonical URL
  def canonical_url(options = {})
    if options[:url].present?
      normalize_url(options[:url])
    else
      base_url = "#{CANONICAL_PROTOCOL}://#{CANONICAL_HOST}#{request.path}"

      # 허용된 파라미터만 포함 (페이지네이션 등)
      if options[:params].present?
        allowed = request.query_parameters.slice(*options[:params])
        base_url += "?#{allowed.to_query}" if allowed.present?
      end

      base_url
    end
  end

  # Canonical link 태그 생성
  # @param options [Hash] canonical_url에 전달할 옵션
  # @return [ActiveSupport::SafeBuffer] link 태그 HTML
  def canonical_tag(options = {})
    tag.link(rel: "canonical", href: canonical_url(options))
  end

  # ==========================================================================
  # JSON-LD Structured Data
  # ==========================================================================

  # Organization 스키마 (사이트 전역)
  # @return [ActiveSupport::SafeBuffer] JSON-LD script 태그
  def organization_json_ld
    data = {
      "@context" => "https://schema.org",
      "@type" => "Organization",
      "name" => "Undrew",
      "alternateName" => "언드루",
      "url" => "https://#{CANONICAL_HOST}",
      "logo" => "https://#{CANONICAL_HOST}/icon.png",
      "description" => "아이디어·사람·외주가 한 공간에서 연결되는 최초의 창업 커뮤니티"
    }

    json_ld_script_tag(data)
  end

  # WebSite 스키마 (검색 기능 포함)
  # @return [ActiveSupport::SafeBuffer] JSON-LD script 태그
  def website_json_ld
    data = {
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => "Undrew",
      "url" => "https://#{CANONICAL_HOST}",
      "potentialAction" => {
        "@type" => "SearchAction",
        "target" => {
          "@type" => "EntryPoint",
          "urlTemplate" => "https://#{CANONICAL_HOST}/search?q={search_term_string}"
        },
        "query-input" => "required name=search_term_string"
      }
    }

    json_ld_script_tag(data)
  end

  # Article/BlogPosting 스키마 (게시글용)
  # @param post [Post] 게시글 객체
  # @return [ActiveSupport::SafeBuffer] JSON-LD script 태그
  def article_json_ld(post)
    description = if post.content.respond_to?(:to_plain_text)
      post.content.to_plain_text.truncate(200)
    else
      post.content.to_s.truncate(200)
    end

    data = {
      "@context" => "https://schema.org",
      "@type" => post.outsourcing? ? "Article" : "BlogPosting",
      "headline" => post.title.truncate(110),
      "description" => description,
      "author" => {
        "@type" => "Person",
        "name" => post.user.display_name,
        "url" => "https://#{CANONICAL_HOST}#{profile_path(post.user)}"
      },
      "publisher" => {
        "@type" => "Organization",
        "name" => "Undrew",
        "logo" => {
          "@type" => "ImageObject",
          "url" => "https://#{CANONICAL_HOST}/icon.png"
        }
      },
      "mainEntityOfPage" => {
        "@type" => "WebPage",
        "@id" => "https://#{CANONICAL_HOST}#{post_path(post)}"
      },
      "datePublished" => post.created_at.iso8601,
      "dateModified" => post.updated_at.iso8601
    }

    # 이미지가 있으면 추가
    if post.images.attached?
      data["image"] = url_for(post.images.first)
    end

    json_ld_script_tag(data)
  end

  # BreadcrumbList 스키마
  # @param items [Array<Hash>] 빵 부스러기 항목 배열
  #   각 항목: { name: "홈", url: "/" }
  # @return [ActiveSupport::SafeBuffer] JSON-LD script 태그
  def breadcrumb_json_ld(items)
    list_items = items.each_with_index.map do |item, index|
      {
        "@type" => "ListItem",
        "position" => index + 1,
        "name" => item[:name],
        "item" => item[:url].start_with?("http") ? item[:url] : "https://#{CANONICAL_HOST}#{item[:url]}"
      }
    end

    data = {
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => list_items
    }

    json_ld_script_tag(data)
  end

  private

  # URL 정규화 (www 제거, https 강제)
  def normalize_url(url)
    uri = URI.parse(url)
    "#{CANONICAL_PROTOCOL}://#{CANONICAL_HOST}#{uri.path}"
  rescue URI::InvalidURIError
    url
  end

  # JSON-LD script 태그 생성
  def json_ld_script_tag(data)
    tag.script(type: "application/ld+json") do
      data.to_json.html_safe
    end
  end
end
