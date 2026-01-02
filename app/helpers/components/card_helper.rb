module Components::CardHelper
  def render_card(title: nil, subtitle: nil, body: nil, footer: nil, **options, &block)
    render "components/ui/card", title: title, subtitle: subtitle, footer: footer, body: (block ? capture(&block) : body), block:, options: options
  end

  # 통합 Post Card 컴포넌트 - undrew-design 스타일
  #
  # 사용 예시:
  #   <%= render_post_card(@post) %>
  #   <%= render_post_card(@post, variant: :compact) %>
  #   <%= render_post_card(@post, variant: :outsourcing, show_author: false) %>
  #
  # Variants:
  #   - :auto - post.outsourcing? 기반 자동 선택 (기본)
  #   - :community - 커뮤니티 스타일
  #   - :outsourcing - 외주 스타일 (구인/구직)
  #   - :compact - 컴팩트 스타일 (프로필 페이지용)
  #   - :grid - 그리드 레이아웃 최적화
  #
  # Options:
  #   - show_author: true/false (기본: true)
  #   - show_actions: true/false (기본: true)
  #   - show_image: true/false (기본: true)
  #   - image_position: :right, :top (기본: :right)
  #
  def render_post_card(post, variant: :auto, show_author: true, show_actions: true, show_image: true, image_position: :right, **options)
    # 자동 variant 결정
    actual_variant = if variant == :auto
      post.respond_to?(:outsourcing?) && post.outsourcing? ? :outsourcing : :community
    else
      variant
    end

    render "posts/post_card",
           post: post,
           variant: actual_variant,
           show_author: show_author,
           show_actions: show_actions,
           show_image: show_image,
           image_position: image_position,
           **options
  end
end
