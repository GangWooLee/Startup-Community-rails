module ApplicationHelper
  # 결제 시스템 활성화 여부
  # 사업자등록 완료 후 true로 변경하면 결제 기능 활성화
  # 관련 파일: payments_controller.rb, orders_controller.rb, TossPayments 서비스
  def payment_enabled?
    false
  end

  # Open Graph 메타 태그 생성 헬퍼
  # 소셜 미디어 공유 시 링크 미리보기에 사용됨
  def og_meta_tags(options = {})
    # 기본값 설정
    # URL 인코딩 문제 방지를 위해 force_encoding 적용
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
    tags << tag.meta(property: "og:title", content: opts[:title].to_s.force_encoding("UTF-8"))
    tags << tag.meta(property: "og:description", content: opts[:description].to_s.force_encoding("UTF-8"))
    tags << tag.meta(property: "og:type", content: opts[:type])
    tags << tag.meta(property: "og:url", content: opts[:url].to_s.force_encoding("UTF-8"))
    tags << tag.meta(property: "og:site_name", content: "Undrew")
    tags << tag.meta(property: "og:locale", content: "ko_KR")

    if opts[:image].present?
      tags << tag.meta(property: "og:image", content: opts[:image])
      tags << tag.meta(property: "og:image:width", content: "1200")
      tags << tag.meta(property: "og:image:height", content: "630")
    end

    # Twitter Card 태그
    tags << tag.meta(name: "twitter:card", content: opts[:image].present? ? "summary_large_image" : "summary")
    tags << tag.meta(name: "twitter:title", content: opts[:title].to_s.force_encoding("UTF-8"))
    tags << tag.meta(name: "twitter:description", content: opts[:description].to_s.force_encoding("UTF-8"))
    tags << tag.meta(name: "twitter:image", content: opts[:image]) if opts[:image].present?

    safe_join(tags, "\n    ".dup.force_encoding("UTF-8"))
  end

  # 게시글용 OG 메타 태그 생성
  def post_og_meta_tags(post)
    image_url = nil
    if post.images.attached?
      # 첫 번째 이미지 사용
      image_url = url_for(post.images.first)
    end

    og_meta_tags(
      title: post.title,
      description: post.content.truncate(100),
      type: "article",
      image: image_url
    )
  end

  # 검색어를 하이라이팅하여 표시
  # text: 원본 텍스트
  # query: 검색어
  # 반환: 검색어 부분이 <mark>로 감싸진 HTML safe 문자열
  def highlight_search(text, query)
    return "" if text.blank?
    return h(text) if query.blank?

    # 대소문자 무시하고 검색어 찾기
    escaped_query = Regexp.escape(query)
    regex = /(#{escaped_query})/i

    # 검색어를 <mark> 태그로 감싸기
    highlighted = h(text).gsub(regex) do |match|
      "<mark class=\"bg-yellow-200 text-foreground px-0.5 rounded\">#{match}</mark>"
    end

    highlighted.html_safe
  end

  # 텍스트를 검색어 주변으로 잘라서 하이라이팅
  # text: 원본 텍스트
  # query: 검색어
  # max_length: 최대 길이
  def highlight_snippet(text, query, max_length: 100)
    return "" if text.blank?
    return h(text.truncate(max_length)) if query.blank?

    # 검색어 위치 찾기
    query_pos = text.downcase.index(query.downcase)

    if query_pos
      # 검색어 앞뒤로 텍스트 추출
      start_pos = [query_pos - 30, 0].max
      end_pos = [query_pos + query.length + 70, text.length].min

      snippet = text[start_pos...end_pos]
      snippet = "..." + snippet if start_pos > 0
      snippet = snippet + "..." if end_pos < text.length

      highlight_search(snippet, query)
    else
      highlight_search(text.truncate(max_length), query)
    end
  end

  # 페이지네이션 범위 계산 (1 2 3 ... 10 형태)
  # current_page: 현재 페이지
  # total_pages: 전체 페이지 수
  # 반환: 페이지 번호 배열 (... 은 :ellipsis로 표시)
  def pagination_range(current_page, total_pages)
    return [] if total_pages <= 0
    return [1] if total_pages == 1

    # 표시할 최대 페이지 수
    max_visible = 5

    if total_pages <= max_visible
      # 전체 페이지가 적으면 모두 표시
      (1..total_pages).to_a
    else
      pages = []

      # 항상 첫 페이지 표시
      pages << 1

      # 현재 페이지 주변 계산
      if current_page <= 3
        # 앞쪽에 있을 때: 1 2 3 4 ... 10
        pages.concat((2..[4, total_pages - 1].min).to_a)
        pages << :ellipsis if total_pages > 5
      elsif current_page >= total_pages - 2
        # 뒤쪽에 있을 때: 1 ... 7 8 9 10
        pages << :ellipsis if total_pages > 5
        pages.concat(([total_pages - 3, 2].max..total_pages - 1).to_a)
      else
        # 중간에 있을 때: 1 ... 5 6 7 ... 10
        pages << :ellipsis
        pages.concat((current_page - 1..current_page + 1).to_a)
        pages << :ellipsis
      end

      # 항상 마지막 페이지 표시
      pages << total_pages

      pages.uniq
    end
  end

  # 아바타 배경색 생성 (이름 기반)
  # 이름의 첫 글자를 기반으로 일관된 색상 반환
  def avatar_bg_color(name)
    return "bg-gray-400" if name.blank?

    colors = %w[
      bg-red-500 bg-orange-500 bg-amber-500 bg-yellow-500
      bg-lime-500 bg-green-500 bg-emerald-500 bg-teal-500
      bg-cyan-500 bg-sky-500 bg-blue-500 bg-indigo-500
      bg-violet-500 bg-purple-500 bg-fuchsia-500 bg-pink-500
    ]

    # 이름의 첫 글자 코드값으로 색상 선택
    index = name.chars.first.ord % colors.length
    colors[index]
  end

  # 메시지 미리보기 텍스트 생성
  def message_preview(message)
    case message.message_type
    when "system"
      truncate(message.content, length: 30)
    when "deal_confirm"
      "거래가 확정되었습니다"
    when "profile_card"
      "프로필을 공유했습니다"
    when "contact_card"
      "연락처를 공유했습니다"
    else
      truncate(message.content, length: 30)
    end
  end

  # 사용자 아바타 렌더링 헬퍼
  # 다양한 컨텍스트에서 일관된 아바타 렌더링을 제공
  # (shadcn render_avatar와 구분하기 위해 render_user_avatar로 명명)
  #
  # @param user [User] 사용자 객체
  # @param options [Hash] 옵션
  #   :size - "xs" | "sm" | "md" | "lg" | "xl" | "2xl" (기본: "md")
  #   :class - 컨테이너에 추가할 CSS 클래스
  #   :ring - 링 스타일 (예: "ring-2 ring-background")
  #   :fallback_bg - 폴백 배경색 (기본: "bg-secondary")
  #   :fallback_text_color - 폴백 텍스트 색상 (기본: "text-muted-foreground")
  #   :variant - 이미지 variant (예: :thumb)
  #
  # 사용 예시:
  #   <%= render_user_avatar(@user) %>
  #   <%= render_user_avatar(@user, size: "lg", ring: "ring-4 ring-background") %>
  #   <%= render_user_avatar(@user, size: "sm", class: "shadow-lg") %>
  def render_user_avatar(user, options = {})
    return "" unless user

    size = options.fetch(:size, "md")
    extra_class = options.fetch(:class, "")
    ring_class = options.fetch(:ring, "")
    fallback_bg = options.fetch(:fallback_bg, "bg-secondary")
    fallback_text_color = options.fetch(:fallback_text_color, "text-muted-foreground")
    variant = options[:variant]

    # 사이즈별 클래스 매핑
    size_classes = {
      "xs" => { container: "h-5 w-5", text: "text-[10px]" },
      "sm" => { container: "h-8 w-8", text: "text-sm" },
      "md" => { container: "h-10 w-10", text: "text-lg" },
      "lg" => { container: "h-12 w-12", text: "text-xl" },
      "xl" => { container: "h-16 w-16", text: "text-2xl" },
      "2xl" => { container: "h-20 w-20", text: "text-2xl" }
    }

    sizes = size_classes[size] || size_classes["md"]
    container_class = [
      sizes[:container],
      "rounded-full overflow-hidden flex items-center justify-center flex-shrink-0",
      fallback_bg,
      ring_class,
      extra_class
    ].reject(&:blank?).join(" ")

    # 아바타 이미지 또는 폴백 렌더링
    content = if user.respond_to?(:avatar) && user.avatar.attached?
      img_src = variant ? user.avatar.variant(variant) : user.avatar
      image_tag(img_src, alt: user.name, class: "h-full w-full object-cover")
    elsif user.respond_to?(:avatar_url) && user.avatar_url.present?
      image_tag(user.avatar_url, alt: user.name, class: "h-full w-full object-cover")
    else
      # 폴백: 이름 첫 글자
      initial = user.name&.first&.upcase || "?"
      content_tag(:span, initial, class: "#{sizes[:text]} font-semibold #{fallback_text_color}")
    end

    content_tag(:div, content, class: container_class)
  end
end
