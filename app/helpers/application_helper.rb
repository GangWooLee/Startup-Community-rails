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
      start_pos = [ query_pos - 30, 0 ].max
      end_pos = [ query_pos + query.length + 70, text.length ].min

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
    return [ 1 ] if total_pages == 1

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
        pages.concat((2..[ 4, total_pages - 1 ].min).to_a)
        pages << :ellipsis if total_pages > 5
      elsif current_page >= total_pages - 2
        # 뒤쪽에 있을 때: 1 ... 7 8 9 10
        pages << :ellipsis if total_pages > 5
        pages.concat(([ total_pages - 3, 2 ].max..total_pages - 1).to_a)
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

    # 익명 모드일 때는 흰색 배경 + 테두리 사용
    is_anonymous = user.respond_to?(:using_anonymous_avatar?) && user.using_anonymous_avatar?
    bg_class = is_anonymous ? "bg-white border border-gray-200" : fallback_bg

    container_class = [
      sizes[:container],
      "rounded-full overflow-hidden flex items-center justify-center flex-shrink-0",
      bg_class,
      ring_class,
      extra_class
    ].reject(&:blank?).join(" ")

    # 아바타 이미지 또는 폴백 렌더링
    # ★ 핵심: 익명 모드 우선 체크 (Single Source of Truth)
    content = if is_anonymous
      # 익명 아바타 이미지
      avatar_type = user.respond_to?(:avatar_type) ? user.avatar_type.to_i : 0
      image_tag("/anonymous#{avatar_type + 1}-.png",
                alt: user.display_name,
                class: "h-full w-full object-cover")
    elsif user.respond_to?(:avatar) && user.avatar.attached?
      img_src = variant ? user.avatar.variant(variant) : user.avatar
      image_tag(img_src, alt: user.display_name, class: "h-full w-full object-cover")
    elsif user.respond_to?(:avatar_url) && user.avatar_url.present?
      image_tag(user.avatar_url, alt: user.display_name, class: "h-full w-full object-cover")
    else
      # 폴백: display_name 첫 글자 (익명이면 닉네임 첫 글자)
      display = user.respond_to?(:display_name) ? user.display_name : user.name
      initial = display&.first&.upcase || "?"
      content_tag(:span, initial, class: "#{sizes[:text]} font-semibold #{fallback_text_color}")
    end

    content_tag(:div, content, class: container_class)
  end

  # URL 안전성 검증 (XSS 방지)
  # javascript:, data: 스킴 등 위험한 URL 차단
  # @param url [String] 검증할 URL
  # @return [Boolean] 안전한 URL이면 true
  def safe_url?(url)
    return false if url.blank?

    begin
      uri = URI.parse(url)
      # http, https 프로토콜만 허용
      %w[http https].include?(uri.scheme&.downcase)
    rescue URI::InvalidURIError
      false
    end
  end

  # ============================================================================
  # URL 자동 링크 변환 Helpers (rails_autolink gem 사용)
  # ============================================================================

  # 텍스트 내 URL을 클릭 가능한 하이퍼링크로 변환
  # rails_autolink gem을 사용하여 안전하고 검증된 방식으로 변환
  #
  # @param text [String] 변환할 텍스트
  # @return [ActiveSupport::SafeBuffer] 링크가 포함된 HTML safe 문자열
  #
  # 사용 예시:
  #   <%= linkify_urls("https://google.com 방문하세요") %>
  #   => <a href="https://google.com" ...>https://google.com</a> 방문하세요
  #
  # 지원 형식:
  #   - http://, https:// URL
  #   - www. 로 시작하는 URL
  #
  # 보안:
  #   - XSS 방지: sanitize: true (기본값)
  #   - 새 탭 열기: target="_blank"
  #   - 보안 속성: rel="noopener noreferrer"
  #
  # 참고: rails_autolink gem의 내부 메서드 auto_link_urls와 충돌 방지를 위해
  #       linkify_urls로 명명
  def linkify_urls(text, variant: :default)
    return "".html_safe if text.blank?

    # 컨텍스트별 링크 스타일
    link_class = case variant
    when :light
                   # 채팅용 (흰색 링크)
                   "text-white underline break-all"
    else
                   # 기본 (게시글, 댓글, 프로필 등)
                   "text-primary hover:underline break-all"
    end

    # rails_autolink gem의 auto_link 사용
    # link: :urls - URL만 링크로 변환 (이메일 제외)
    # sanitize: true - XSS 방지 (기본값)
    auto_link(text, {
      html: {
        target: "_blank",
        rel: "noopener noreferrer",
        class: link_class
      },
      link: :urls,
      sanitize: true
    })
  end

  # ============================================================================
  # Global Sidebar Layout Helpers
  # ============================================================================

  # 글로벌 사이드바를 표시할지 결정
  # 로그인/회원가입/랜딩 등 특정 페이지에서는 기존 레이아웃 사용
  # @return [Boolean] 글로벌 사이드바 표시 여부
  def show_global_sidebar?
    # 로그인/회원가입 페이지
    return false if controller_name == "sessions"
    return false if controller_name == "registrations"

    # 비밀번호 관련 페이지
    return false if controller_name == "passwords"

    # 온보딩 랜딩 페이지
    return false if controller_name == "onboarding" && action_name == "landing"

    # 관리자 페이지
    return false if controller_path.start_with?("admin")

    true
  end

  # 사이드바 네비게이션 아이템 렌더링 헬퍼
  # @param label [String] 메뉴 라벨
  # @param path [String] 링크 경로
  # @param icon [Symbol] 아이콘 이름
  # @param options [Hash] 옵션
  #   :is_active - 활성 상태 강제 지정
  #   :badge - 배지 숫자 (알림 등)
  #   :size - :md | :sm
  # @return [String] 렌더링된 HTML
  def sidebar_nav_item(label, path, icon, options = {})
    is_active = options.fetch(:is_active, nil)
    is_active = current_page?(path) if is_active.nil?
    badge = options.fetch(:badge, nil)
    size = options.fetch(:size, :md)

    size_class = size == :sm ? "py-2 text-sm" : "py-2.5"
    active_class = is_active ?
      "text-stone-900 bg-white shadow-sm border border-stone-100 font-bold" :
      "text-stone-600 hover:bg-stone-50 hover:text-stone-900"

    link_to path, class: "flex items-center gap-3 px-3 #{size_class} rounded-lg transition-all #{active_class}" do
      concat(sidebar_icon(icon, active: is_active))
      concat(content_tag(:span, label))
      if badge.present? && badge.to_i > 0
        badge_text = badge.to_i > 99 ? "99+" : badge.to_s
        concat(content_tag(:span, badge_text,
          class: "ml-auto px-1.5 py-0.5 text-xs font-bold bg-red-500 text-white rounded-full"))
      end
    end
  end

  # 사이드바 아이콘 SVG 렌더링
  # @param name [Symbol] 아이콘 이름
  # @param active [Boolean] 활성 상태
  # @return [String] SVG HTML
  def sidebar_icon(name, active: false)
    icon_color = active ? "text-orange-500" : ""
    stroke_width = active ? "0" : "2"
    fill = active ? "currentColor" : "none"

    svg_paths = {
      home: '<path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>',
      chat: '<path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>',
      ai: '<path stroke-linecap="round" stroke-linejoin="round" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/>',
      rocket: '<path stroke-linecap="round" stroke-linejoin="round" d="M15.59 14.37a6 6 0 01-5.84 7.38v-4.8m5.84-2.58a14.98 14.98 0 006.16-12.12A14.98 14.98 0 009.631 8.41m5.96 5.96a14.926 14.926 0 01-5.841 2.58m-.119-8.54a6 6 0 00-7.381 5.84h4.8m2.581-5.84a14.927 14.927 0 00-2.58 5.84m2.699 2.7c-.103.021-.207.041-.311.06a15.09 15.09 0 01-2.448-2.448 14.9 14.9 0 01.06-.312m-2.24 2.39a4.493 4.493 0 00-1.757 4.306 4.493 4.493 0 004.306-1.758M16.5 9a1.5 1.5 0 11-3 0 1.5 1.5 0 013 0z"/>',
      question: '<path stroke-linecap="round" stroke-linejoin="round" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>',
      fire: '<path stroke-linecap="round" stroke-linejoin="round" d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z"/>',
      megaphone: '<path stroke-linecap="round" stroke-linejoin="round" d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z"/>'
    }

    path = svg_paths[name] || svg_paths[:home]

    content_tag(:svg, path.html_safe,
      class: "w-5 h-5 #{icon_color}",
      fill: fill,
      stroke: "currentColor",
      viewBox: "0 0 24 24",
      "stroke-width": stroke_width
    )
  end

  # 읽지 않은 메시지 수 반환 (사이드바 배지용)
  # @return [Integer] 읽지 않은 메시지 수
  def unread_messages_count
    return 0 unless logged_in?
    current_user.total_unread_messages
  end

  # 접이식 사이드바 네비게이션 아이템
  # 펼친 상태: 아이콘 + 텍스트
  # 접힌 상태: 아이콘만 (tooltip으로 텍스트 표시)
  # @param label [String] 메뉴 레이블
  # @param path [String] 링크 경로
  # @param icon [Symbol] 아이콘 이름
  # @param options [Hash] 옵션
  #   :is_active - 활성 상태 강제 지정
  #   :badge - 배지 숫자 (알림 등)
  # @return [String] 렌더링된 HTML
  def collapsible_sidebar_nav_item(label, path, icon, options = {})
    is_active = options.fetch(:is_active, nil)
    is_active = current_page?(path) if is_active.nil?
    badge = options.fetch(:badge, nil)

    active_class = is_active ?
      "text-stone-900 bg-stone-100 font-bold" :
      "text-stone-600 hover:bg-stone-50 hover:text-stone-900"

    # 펼친 상태 (아이콘 + 텍스트)
    expanded_html = link_to path, class: "flex items-center gap-3 px-3 py-2.5 rounded-lg transition-all #{active_class}",
                                  data: { sidebar_collapse_target: "expandedContent" } do
      concat(sidebar_icon(icon, active: is_active))
      concat(content_tag(:span, label, class: "truncate"))
      if badge.present? && badge.to_i > 0
        badge_text = badge.to_i > 99 ? "99+" : badge.to_s
        concat(content_tag(:span, badge_text,
          class: "ml-auto px-1.5 py-0.5 text-xs font-bold bg-red-500 text-white rounded-full"))
      end
    end

    # 접힌 상태 (아이콘만, tooltip)
    collapsed_active_class = is_active ?
      "bg-stone-100" :
      "hover:bg-stone-50"

    collapsed_html = link_to path, class: "hidden flex justify-center p-2.5 rounded-lg transition-all #{collapsed_active_class}",
                                   title: label,
                                   data: { sidebar_collapse_target: "collapsedContent" } do
      concat(content_tag(:div, class: "relative") do
        concat(sidebar_icon(icon, active: is_active))
        if badge.present? && badge.to_i > 0
          concat(content_tag(:span, "",
            class: "absolute -top-1 -right-1 w-2.5 h-2.5 bg-red-500 rounded-full"))
        end
      end)
    end

    (expanded_html + collapsed_html).html_safe
  end
end
