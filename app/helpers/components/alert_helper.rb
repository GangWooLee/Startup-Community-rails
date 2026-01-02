module Components::AlertHelper
  # Alert/Toast 컴포넌트 - undrew-design 스타일
  #
  # 사용 예시:
  #   <%= render_alert "저장되었습니다.", variant: :success %>
  #   <%= render_alert variant: :error, dismissible: true do %>
  #     <strong>오류:</strong> 입력을 확인해주세요.
  #   <% end %>
  #
  # Variants: :default, :success, :error, :warning, :info
  # Options:
  #   - dismissible: true/false (닫기 버튼 표시)
  #   - icon: true/false (아이콘 표시, 기본 true)
  #   - title: "제목" (선택적 제목)
  #
  def render_alert(message = "", variant: :default, dismissible: false, icon: true, title: nil, **options, &block)
    alert_classes = "relative w-full rounded-lg border p-4"

    variant_classes = case variant.to_sym
    when :default
      "bg-background text-foreground border-border"
    when :success
      "bg-green-50 border-green-200 text-green-800"
    when :error, :destructive
      "bg-destructive/10 border-destructive/20 text-destructive"
    when :warning
      "bg-yellow-50 border-yellow-200 text-yellow-800"
    when :info
      "bg-blue-50 border-blue-200 text-blue-800"
    end

    alert_classes = tw(alert_classes, variant_classes, options[:class])
    text = message.present? ? message : (block ? capture(&block) : "")

    render "components/ui/alert",
           text: text,
           alert_classes: alert_classes,
           dismissible: dismissible,
           icon: icon,
           title: title,
           variant: variant,
           **options.except(:class)
  end

  private

  def alert_icon_for(variant)
    case variant.to_sym
    when :success
      '<svg class="h-5 w-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>'
    when :error, :destructive
      '<svg class="h-5 w-5 text-destructive" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>'
    when :warning
      '<svg class="h-5 w-5 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>'
    when :info
      '<svg class="h-5 w-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>'
    else
      '<svg class="h-5 w-5 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>'
    end
  end
end
