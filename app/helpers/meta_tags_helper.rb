# frozen_string_literal: true

# Open Graph 및 Twitter Card 메타 태그 생성 헬퍼
#
# 소셜 미디어 공유 시 링크 미리보기에 사용됨
# UTF-8 인코딩 문제 방지 처리 포함
module MetaTagsHelper
  # Open Graph 메타 태그 생성
  # @param options [Hash] 메타 태그 옵션
  #   :title - 페이지 제목
  #   :description - 페이지 설명
  #   :type - 콘텐츠 타입 (website, article 등)
  #   :image - 이미지 URL
  #   :url - 페이지 URL
  # @return [ActiveSupport::SafeBuffer] 메타 태그 HTML
  def og_meta_tags(options = {})
    current_url = begin
      request.original_url.force_encoding("UTF-8")
    rescue StandardError
      request.base_url
    end

    defaults = {
      title: "Undrew - 창업자 커뮤니티",
      description: "아이디어·사람·외주가 한 공간에서 연결되는 최초의 창업 커뮤니티",
      type: "website",
      image: nil,
      url: current_url
    }

    opts = defaults.merge(options)

    tags = []
    tags << tag.meta(property: "og:title", content: opts[:title].to_s.dup.force_encoding("UTF-8"))
    tags << tag.meta(property: "og:description", content: opts[:description].to_s.dup.force_encoding("UTF-8"))
    tags << tag.meta(property: "og:type", content: opts[:type])
    tags << tag.meta(property: "og:url", content: opts[:url].to_s.dup.force_encoding("UTF-8"))
    tags << tag.meta(property: "og:site_name", content: "Undrew")
    tags << tag.meta(property: "og:locale", content: "ko_KR")

    if opts[:image].present?
      tags << tag.meta(property: "og:image", content: opts[:image])
      tags << tag.meta(property: "og:image:width", content: "1200")
      tags << tag.meta(property: "og:image:height", content: "630")
    end

    # Twitter Card 태그
    tags << tag.meta(name: "twitter:card", content: opts[:image].present? ? "summary_large_image" : "summary")
    tags << tag.meta(name: "twitter:title", content: opts[:title].to_s.dup.force_encoding("UTF-8"))
    tags << tag.meta(name: "twitter:description", content: opts[:description].to_s.dup.force_encoding("UTF-8"))
    tags << tag.meta(name: "twitter:image", content: opts[:image]) if opts[:image].present?

    safe_join(tags, "\n    ".dup.force_encoding("UTF-8"))
  end

  # 게시글용 OG 메타 태그 생성
  # @param post [Post] 게시글 객체
  # @return [ActiveSupport::SafeBuffer] 메타 태그 HTML
  def post_og_meta_tags(post)
    image_url = nil
    if post.images.attached?
      image_url = url_for(post.images.first)
    end

    og_meta_tags(
      title: post.title,
      description: post.content.truncate(100),
      type: "article",
      image: image_url
    )
  end
end
