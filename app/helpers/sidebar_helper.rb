# frozen_string_literal: true

# 글로벌 사이드바 레이아웃 헬퍼
#
# 사이드바 네비게이션 아이템, 아이콘, 접이식 메뉴 렌더링 제공
module SidebarHelper
  # SVG 아이콘 경로 상수
  SIDEBAR_ICON_PATHS = {
    home: '<path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>',
    chat: '<path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>',
    ai: '<path stroke-linecap="round" stroke-linejoin="round" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/>',
    rocket: '<path stroke-linecap="round" stroke-linejoin="round" d="M15.59 14.37a6 6 0 01-5.84 7.38v-4.8m5.84-2.58a14.98 14.98 0 006.16-12.12A14.98 14.98 0 009.631 8.41m5.96 5.96a14.926 14.926 0 01-5.841 2.58m-.119-8.54a6 6 0 00-7.381 5.84h4.8m2.581-5.84a14.927 14.927 0 00-2.58 5.84m2.699 2.7c-.103.021-.207.041-.311.06a15.09 15.09 0 01-2.448-2.448 14.9 14.9 0 01.06-.312m-2.24 2.39a4.493 4.493 0 00-1.757 4.306 4.493 4.493 0 004.306-1.758M16.5 9a1.5 1.5 0 11-3 0 1.5 1.5 0 013 0z"/>',
    question: '<path stroke-linecap="round" stroke-linejoin="round" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>',
    fire: '<path stroke-linecap="round" stroke-linejoin="round" d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z"/>',
    megaphone: '<path stroke-linecap="round" stroke-linejoin="round" d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z"/>',
    info: '<path stroke-linecap="round" stroke-linejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>'
  }.freeze

  # 글로벌 사이드바를 표시할지 결정
  # 로그인/회원가입/랜딩 등 특정 페이지에서는 기존 레이아웃 사용
  # @return [Boolean] 글로벌 사이드바 표시 여부
  def show_global_sidebar?
    return false if controller_name == "sessions"
    return false if controller_name == "registrations"
    return false if controller_name == "passwords"
    return false if controller_name == "onboarding" && action_name == "landing"
    return false if controller_path.start_with?("admin")

    true
  end

  # 사이드바 네비게이션 아이템 렌더링
  # @param label [String] 메뉴 라벨
  # @param path [String] 링크 경로
  # @param icon [Symbol] 아이콘 이름
  # @param options [Hash] 옵션
  #   :is_active - 활성 상태 강제 지정
  #   :badge - 배지 숫자 (알림 등)
  #   :size - :md | :sm
  # @return [ActiveSupport::SafeBuffer] 렌더링된 HTML
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
      concat(render_sidebar_badge(badge)) if badge.present? && badge.to_i > 0
    end
  end

  # 사이드바 아이콘 SVG 렌더링
  # @param name [Symbol] 아이콘 이름
  # @param active [Boolean] 활성 상태
  # @return [ActiveSupport::SafeBuffer] SVG HTML
  def sidebar_icon(name, active: false)
    icon_color = active ? "text-orange-500" : ""
    stroke_width = active ? "0" : "2"
    fill = active ? "currentColor" : "none"
    path = SIDEBAR_ICON_PATHS[name] || SIDEBAR_ICON_PATHS[:home]

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
  # @return [ActiveSupport::SafeBuffer] 렌더링된 HTML
  def collapsible_sidebar_nav_item(label, path, icon, options = {})
    is_active = options.fetch(:is_active, nil)
    is_active = current_page?(path) if is_active.nil?
    badge = options.fetch(:badge, nil)

    expanded_html = render_expanded_sidebar_item(label, path, icon, is_active, badge)
    collapsed_html = render_collapsed_sidebar_item(label, path, icon, is_active, badge)

    (expanded_html + collapsed_html).html_safe
  end

  private

  # 사이드바 배지 렌더링
  def render_sidebar_badge(badge)
    badge_text = badge.to_i > 99 ? "99+" : badge.to_s
    content_tag(:span, badge_text,
      class: "ml-auto px-1.5 py-0.5 text-xs font-bold bg-red-500 text-white rounded-full")
  end

  # 펼친 상태 사이드바 아이템
  # 아이콘을 고정 너비 컨테이너(w-10)에 배치하여 접힘 애니메이션 시 위치 고정
  def render_expanded_sidebar_item(label, path, icon, is_active, badge)
    active_class = is_active ?
      "text-stone-900 bg-stone-100 font-bold" :
      "text-stone-600 hover:bg-stone-50 hover:text-stone-900"

    link_to path, class: "flex items-center py-2.5 rounded-lg transition-all #{active_class}",
                  data: { sidebar_collapse_target: "expandedContent" } do
      concat(content_tag(:div, sidebar_icon(icon, active: is_active),
             class: "w-10 flex-shrink-0 flex justify-center"))
      concat(content_tag(:span, label, class: "truncate"))
      concat(render_sidebar_badge(badge)) if badge.present? && badge.to_i > 0
    end
  end

  # 접힌 상태 사이드바 아이템
  # 아이콘을 고정 너비 컨테이너(w-10)에 배치하여 펼침과 동일한 위치 유지
  def render_collapsed_sidebar_item(label, path, icon, is_active, badge)
    collapsed_active_class = is_active ? "bg-stone-100" : "hover:bg-stone-50"

    link_to path, class: "hidden flex items-center py-2.5 rounded-lg transition-all #{collapsed_active_class}",
                  title: label,
                  data: { sidebar_collapse_target: "collapsedContent" } do
      concat(content_tag(:div, class: "w-10 flex-shrink-0 flex justify-center relative") do
        concat(sidebar_icon(icon, active: is_active))
        if badge.present? && badge.to_i > 0
          concat(content_tag(:span, "",
            class: "absolute -top-1 -right-1 w-2.5 h-2.5 bg-red-500 rounded-full"))
        end
      end)
    end
  end
end
