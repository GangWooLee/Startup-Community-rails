# frozen_string_literal: true

# 프로필 페이지 헬퍼
module ProfilesHelper
  # 프라이버시 블러 래퍼
  # 비공개 섹션을 블러 처리하고 오버레이 메시지를 표시
  #
  # @param visible [Boolean] true면 정상 표시, false면 블러 처리
  # @param message [String] 블러 시 표시할 메시지
  # @yield 블러 처리할 콘텐츠 블록
  # @return [String] 렌더링된 HTML
  #
  # @example
  #   <%= privacy_blur_wrapper(visible: user.about_visible_to?(viewer)) do %>
  #     <!-- 소개 콘텐츠 -->
  #   <% end %>
  def privacy_blur_wrapper(visible:, message: "익명 사용자입니다", &block)
    return capture(&block) if visible

    content_tag(:div, class: "relative min-h-[200px]") do
      # 블러 처리된 콘텐츠
      blurred_content = content_tag(:div, class: "filter blur-sm select-none pointer-events-none opacity-40") do
        capture(&block)
      end

      # 오버레이 (잠금 아이콘 + 메시지)
      overlay = content_tag(:div, class: "absolute inset-0 flex items-center justify-center bg-white/70 dark:bg-gray-900/70 rounded-xl") do
        content_tag(:div, class: "text-center p-6") do
          lock_icon + content_tag(:p, message, class: "text-muted-foreground text-sm mt-3")
        end
      end

      blurred_content + overlay
    end
  end

  private

  # 잠금 아이콘 SVG
  def lock_icon
    content_tag(:div, class: "w-12 h-12 mx-auto rounded-full bg-secondary flex items-center justify-center") do
      raw <<~SVG
        <svg class="w-6 h-6 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
        </svg>
      SVG
    end
  end
end
