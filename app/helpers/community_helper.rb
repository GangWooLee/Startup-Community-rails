# frozen_string_literal: true

##
# Community Helper - Organic Modern 커뮤니티 페이지용 헬퍼
#
# Weekly Best, Top Makers, My Community 등 데이터 쿼리와
# 커뮤니티 페이지 전용 UI 헬퍼 메서드를 제공합니다.
#
module CommunityHelper
  # ============================================================================
  # Constants
  # ============================================================================

  # My Community 목업 데이터 (UI 데모용)
  MY_COMMUNITIES = [
    { name: "UI/UX Design", color: "bg-indigo-400" },
    { name: "Frontend Dev", color: "bg-emerald-400" },
    { name: "React Korea", color: "bg-blue-400" },
    { name: "Startup Founders", color: "bg-orange-400" }
  ].freeze

  # 좌측 사이드바 네비게이션 메뉴
  SIDEBAR_NAV_ITEMS = [
    { name: "홈", path: :community_path, icon: "home", active_icon: "home" },
    { name: "인기", path: :popular_posts_path, icon: "fire", active_icon: "fire" },
    { name: "자유게시판", path: :free_posts_path, icon: "chat-bubble-left-right", active_icon: "chat-bubble-left-right" },
    { name: "Q&A", path: :question_posts_path, icon: "question-mark-circle", active_icon: "question-mark-circle" },
    { name: "프로젝트 찾기", path: :job_posts_path, icon: "rocket-launch", active_icon: "rocket-launch" }
  ].freeze

  # ============================================================================
  # Data Queries
  # ============================================================================

  ##
  # Weekly Best - 최근 7일 내 가장 인기 있는 게시글
  #
  # 인기 점수 = (likes * 2) + comments + (views / 10)
  #
  # @param category [String, Symbol, nil] 카테고리 필터 (nil이면 전체 커뮤니티)
  # @return [Post, nil] 가장 인기 있는 게시글 또는 nil
  #
  def weekly_best_post(category: nil)
    # 카테고리별로 별도 캐싱
    cache_key = category.present? ? "weekly_best_#{category}" : "weekly_best_all"
    cache_var = "@#{cache_key.gsub('-', '_')}"

    return instance_variable_get(cache_var) if instance_variable_defined?(cache_var)

    instance_variable_set(cache_var, begin
      base_query = Post.published

      # 카테고리 필터 적용
      base_query = if category.present?
                     base_query.where(category: category)
      else
                     base_query.community
      end

      post = base_query.where("posts.created_at >= ?", 7.days.ago)
                       .select("posts.*, (COALESCE(likes_count, 0) * 2 + COALESCE(comments_count, 0) + COALESCE(views_count, 0) / 10) AS popularity_score")
                       .order("popularity_score DESC")
                       .includes(:user, images_attachments: :blob)
                       .first

      # 7일 내 게시글이 없으면 전체 기간에서 가장 인기 있는 글로 폴백
      post || base_query.order(likes_count: :desc, views_count: :desc)
                        .includes(:user, images_attachments: :blob)
                        .first
    end)
  end

  ##
  # Top Makers - 최근 30일 내 가장 활발한 사용자 랭킹
  #
  # 활동 점수 = SUM(본인 글의 likes_count + comments_count)
  #
  # @param limit [Integer] 반환할 사용자 수 (기본: 3)
  # @return [Array<User>] 랭킹된 사용자 배열 (engagement_score 속성 포함)
  #
  def top_makers(limit: 3)
    @top_makers ||= begin
      User.active
          .joins(:posts)
          .where(posts: { status: :published, category: [ :free, :question, :promotion ] })
          .where("posts.created_at >= ?", 30.days.ago)
          .group("users.id")
          .select("users.*, (SUM(COALESCE(posts.likes_count, 0)) + SUM(COALESCE(posts.comments_count, 0))) AS engagement_score")
          .order("engagement_score DESC")
          .includes(avatar_attachment: :blob)
          .limit(limit)
    end
  end

  ##
  # Popular Tags - 최근 N일 내 가장 많이 사용된 스킬 태그
  #
  # Post.skills 컬럼(comma-separated)에서 태그를 추출하여 집계합니다.
  #
  # @param limit [Integer] 반환할 태그 수 (기본: 5)
  # @param days [Integer] 집계 기간 (기본: 7일)
  # @return [Array<Hash>] 태그 배열 [{rank:, name:, count:}, ...]
  #
  def popular_tags(limit: 5, days: 7)
    @popular_tags ||= begin
      # 최근 N일 이내 게시글의 skills 수집
      recent_skills = Post.published
                          .where(created_at: days.days.ago..)
                          .where.not(skills: [ nil, "" ])
                          .pluck(:skills)

      # 모든 스킬을 파싱하여 카운트
      tag_counts = Hash.new(0)
      recent_skills.each do |skills_str|
        skills_str.split(",").map(&:strip).reject(&:blank?).each do |skill|
          # 대소문자 통일하여 집계
          tag_counts[skill.downcase] += 1
        end
      end

      # 정렬 후 상위 N개 반환
      tag_counts.sort_by { |_, count| -count }
                .first(limit)
                .map.with_index(1) do |(name, count), rank|
                  { rank: rank, name: name.titleize, count: count }
                end
    end
  end

  ##
  # My Community 목업 데이터 반환
  #
  # @return [Array<Hash>] 커뮤니티 목업 데이터
  #
  def my_communities
    MY_COMMUNITIES
  end

  ##
  # 사이드바 네비게이션 아이템 반환
  #
  # @return [Array<Hash>] 네비게이션 아이템 배열
  #
  def sidebar_nav_items
    SIDEBAR_NAV_ITEMS
  end

  # ============================================================================
  # UI Helpers
  # ============================================================================

  ##
  # 랭킹 뱃지 색상 클래스 반환
  #
  # @param rank [Integer] 순위 (1, 2, 3)
  # @return [String] Tailwind 배경색 클래스
  #
  def rank_badge_color(rank)
    case rank
    when 1 then "bg-yellow-400"    # Gold
    when 2 then "bg-stone-400"     # Silver
    when 3 then "bg-orange-600"    # Bronze
    else "bg-stone-300"
    end
  end

  ##
  # 랭킹 뱃지 링 색상 클래스 반환
  #
  # @param rank [Integer] 순위
  # @return [String] Tailwind ring 색상 클래스
  #
  def rank_ring_color(rank)
    case rank
    when 1 then "ring-yellow-400/30"
    when 2 then "ring-stone-300/30"
    when 3 then "ring-orange-400/30"
    else "ring-stone-200/30"
    end
  end

  ##
  # engagement_score를 사람이 읽기 쉬운 형태로 변환
  #
  # @param score [Integer] 점수
  # @return [String] 포맷된 점수 (예: "4.2k", "1.5k", "892")
  #
  def format_engagement_score(score)
    return "0" if score.nil? || score.zero?

    if score >= 1000
      "#{(score / 1000.0).round(1)}k"
    else
      score.to_s
    end
  end

  ##
  # 조회수를 사람이 읽기 쉬운 형태로 변환
  #
  # @param count [Integer] 조회수
  # @return [String] 포맷된 조회수 (예: "1.2k", "892")
  #
  def format_views_count(count)
    return "0" if count.nil? || count.zero?

    if count >= 1000
      "#{(count / 1000.0).round(1)}k"
    else
      count.to_s
    end
  end

  ##
  # 현재 경로가 특정 nav item과 일치하는지 확인
  #
  # @param item [Hash] 네비게이션 아이템
  # @return [Boolean] 활성 상태 여부
  #
  def nav_item_active?(item)
    path = send(item[:path]) rescue nil
    return false unless path

    current_page?(path)
  end

  ##
  # 카테고리별 필터 경로 생성 헬퍼
  # (실제 라우트가 없으면 community_path에 params 추가)
  #
  def category_filter_path(category)
    case category
    when :popular
      community_path(sort: :popular)
    when :free, :question, :promotion
      community_path(category: category)
    else
      community_path
    end
  end

  ##
  # 정렬 버튼 활성 상태 클래스
  #
  # @param sort_type [Symbol] :recent 또는 :popular
  # @param current_sort [Symbol] 현재 정렬 상태
  # @return [String] Tailwind 클래스
  #
  def sort_button_class(sort_type, current_sort = :recent)
    if sort_type == current_sort
      "px-3 py-1.5 rounded-md bg-white shadow-sm text-stone-900"
    else
      "px-3 py-1.5 rounded-md hover:bg-white/50 hover:text-stone-700 transition-colors"
    end
  end
end
