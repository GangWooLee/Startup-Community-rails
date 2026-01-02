module Components::ModalHelper
  # Modal/Dialog 컴포넌트 - undrew-design 스타일
  #
  # 사용 예시:
  #   <%= render_modal title: "확인", description: "정말 삭제하시겠습니까?" do %>
  #     <div class="flex gap-2 justify-end">
  #       <%= render_button "취소", variant: :outline, data: { action: "modal#close" } %>
  #       <%= render_button "삭제", variant: :destructive %>
  #     </div>
  #   <% end %>
  #
  # Sizes: :sm, :md, :lg, :xl, :full
  # Options:
  #   - id: 모달 ID (기본: "modal-{랜덤}")
  #   - closable: 배경/X버튼 클릭으로 닫기 가능 여부 (기본: true)
  #   - show: 초기 표시 여부 (기본: false)
  #
  def render_modal(title: nil, description: nil, size: :md, id: nil, closable: true, show: false, **options, &block)
    modal_id = id || "modal-#{SecureRandom.hex(4)}"

    size_classes = case size.to_sym
    when :sm then "max-w-sm"
    when :md then "max-w-md"
    when :lg then "max-w-lg"
    when :xl then "max-w-xl"
    when :full then "max-w-4xl"
    end

    content = block ? capture(&block) : ""

    render "components/ui/modal",
           modal_id: modal_id,
           title: title,
           description: description,
           size_classes: size_classes,
           closable: closable,
           show: show,
           content: content,
           **options.except(:class)
  end

  # 모달 트리거 버튼 헬퍼
  def modal_trigger(label, target:, variant: :default, **options, &block)
    data = (options[:data] || {}).merge(action: "modal#open", "modal-target-param": target)
    render_button(label, variant: variant, data: data, **options.except(:data), &block)
  end
end
