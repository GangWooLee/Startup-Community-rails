class SearchController < ApplicationController
  before_action :hide_floating_button

  # 검색 결과 제한
  USERS_LIMIT = 5        # 전체 탭에서 유저 표시 제한
  USERS_PER_PAGE = 10    # 유저 탭에서 페이지당 유저 수
  POSTS_LIMIT = 5        # 전체 탭에서 게시글 표시 제한
  POSTS_PER_PAGE = 10    # 게시글 탭에서 페이지당 게시글 수

  # 탭 종류
  TABS = %w[all users posts].freeze

  # 게시글 카테고리 필터
  POST_CATEGORIES = %w[all community hiring seeking].freeze

  def index
    @query = params[:q].to_s.strip
    @tab = TABS.include?(params[:tab]) ? params[:tab] : "all"
    @category = POST_CATEGORIES.include?(params[:category]) ? params[:category] : "all"

    @page = (params[:page] || 1).to_i

    if @query.present? && @query.length >= 1
      case @tab
      when "users"
        search_users_paginated
        @posts = []
        @posts_total_count = 0
        @posts_page = 1
        @posts_total_pages = 0
      when "posts"
        search_posts_paginated
        @users = []
        @users_total_count = 0
        @users_page = 1
        @users_total_pages = 0
      else # "all"
        search_users(limit: USERS_LIMIT)
        search_posts(limit: POSTS_LIMIT)
        @users_page = 1
        @users_total_pages = 0
        @posts_page = 1
        @posts_total_pages = 0
      end
    else
      @users = []
      @posts = []
      @users_total_count = 0
      @posts_total_count = 0
      @users_page = 1
      @users_total_pages = 0
      @posts_page = 1
      @posts_total_pages = 0
    end

    # 실시간 검색이 아닐 때만 최근 검색어 저장 + GA4 이벤트
    if logged_in? && @query.present? && !live_search_request?
      save_recent_search
      # GA4 검색 이벤트
      track_ga4_event("search", {
        search_term: @query.truncate(100),
        tab: @tab
      })
    end

    # 최근 검색어 로드
    @recent_searches = load_recent_searches

    respond_to do |format|
      format.html do
        if drilldown_request?
          # Drill-down 모달용 결과 (전체 리스트)
          render partial: "search/modal_drilldown", locals: drilldown_locals, layout: false
        elsif modal_search_request?
          # Command Palette 모달용 결과 (Turbo Frame)
          render partial: "search/modal_results", locals: modal_result_locals, layout: false
        elsif live_search_request?
          render partial: "search/results", locals: result_locals, layout: false
        else
          render :index
        end
      end

      # Task 88: Turbo Stream append 패턴 - "더 보기" 클릭 시 기존 아이템 유지 + 새 아이템 추가
      format.turbo_stream do
        if drilldown_append_request?
          items = @tab == "users" ? @users : @posts
          total_count = @tab == "users" ? @users_total_count : @posts_total_count
          total_pages = @tab == "users" ? @users_total_pages : @posts_total_pages
          has_more = @page < total_pages

          render turbo_stream: [
            # 새 아이템들을 기존 리스트에 append
            turbo_stream.append(
              "drilldown_items_#{@tab}",
              partial: "search/drilldown_items",
              locals: { drilldown_type: @tab, items: items }
            ),
            # 더 보기 버튼 업데이트 (다음 페이지 있으면 교체, 없으면 제거)
            if has_more
              turbo_stream.replace(
                "drilldown_load_more",
                partial: "search/drilldown_load_more",
                locals: { query: @query, drilldown_type: @tab, next_page: @page + 1, total_count: total_count }
              )
            else
              turbo_stream.remove("drilldown_load_more")
            end
          ].compact
        end
      end
    end
  end

  # 최근 검색어 삭제
  def destroy_recent
    query_to_delete = params[:query]
    recent = load_recent_searches
    recent.delete(query_to_delete)

    cookies[:recent_searches] = {
      value: recent.to_json,
      expires: 30.days.from_now
    }

    redirect_to search_path, status: :see_other
  end

  # 최근 검색어 전체 삭제
  def clear_recent
    cookies.delete(:recent_searches)
    redirect_to search_path, status: :see_other
  end

  private

  def result_locals
    {
      query: @query,
      tab: @tab,
      category: @category,
      users: @users,
      posts: @posts,
      users_total_count: @users_total_count,
      posts_total_count: @posts_total_count,
      users_page: @users_page,
      users_total_pages: @users_total_pages,
      posts_page: @posts_page,
      posts_total_pages: @posts_total_pages,
      recent_searches: @recent_searches
    }
  end

  # 실시간 검색 요청인지 확인
  def live_search_request?
    request.xhr? || params[:live] == "true"
  end

  # Command Palette 모달 검색 요청인지 확인
  def modal_search_request?
    params[:modal] == "true"
  end

  # Drill-down 요청인지 확인 (모달 내 "모두 보기")
  def drilldown_request?
    params[:modal] == "true" && params[:drilldown] == "true"
  end

  # Task 88: Drill-down append 요청인지 확인 ("더 보기" 클릭)
  def drilldown_append_request?
    params[:modal] == "true" && params[:drilldown] == "true" && params[:append] == "true"
  end

  # 모달용 결과 locals (컴팩트 버전)
  def modal_result_locals
    {
      query: @query,
      users: @users.first(3),           # 모달에서는 3명만 표시
      posts: @posts.first(5),           # 모달에서는 5개만 표시
      users_total_count: @users_total_count,
      posts_total_count: @posts_total_count
    }
  end

  # Drill-down 모달용 locals (전체 리스트)
  def drilldown_locals
    {
      query: @query,
      drilldown_type: @tab,  # "users" or "posts"
      items: @tab == "users" ? @users : @posts,
      total_count: @tab == "users" ? @users_total_count : @posts_total_count,
      current_page: @page,
      has_more_pages: @tab == "users" ? @users_page < @users_total_pages : @posts_page < @posts_total_pages,
      next_page: @page + 1
    }
  end

  # 사용자 검색 (전체 탭용 - 제한된 수만 표시)
  def search_users(limit: USERS_LIMIT)
    query_pattern = "%#{sanitize_like(@query)}%"

    @users = User.where(
      "name LIKE :q OR role_title LIKE :q OR bio LIKE :q OR affiliation LIKE :q",
      q: query_pattern
    ).order(created_at: :desc).limit(limit)

    @users_total_count = User.where(
      "name LIKE :q OR role_title LIKE :q OR bio LIKE :q OR affiliation LIKE :q",
      q: query_pattern
    ).count
  end

  # 사용자 검색 (유저 탭용 - 페이지네이션)
  def search_users_paginated
    query_pattern = "%#{sanitize_like(@query)}%"

    base_query = User.where(
      "name LIKE :q OR role_title LIKE :q OR bio LIKE :q OR affiliation LIKE :q",
      q: query_pattern
    )

    @users_total_count = base_query.count
    @users_total_pages = (@users_total_count.to_f / USERS_PER_PAGE).ceil
    @users_page = [[@page, 1].max, [@users_total_pages, 1].max].min

    offset = (@users_page - 1) * USERS_PER_PAGE
    @users = base_query.order(created_at: :desc).offset(offset).limit(USERS_PER_PAGE)
  end

  # 게시글 검색 (전체 탭용 - 제한된 수만 표시)
  def search_posts(limit: POSTS_LIMIT)
    query_pattern = "%#{sanitize_like(@query)}%"

    base_query = Post.published
                     .includes(:user, images_attachments: :blob)
                     .where("title LIKE :q OR content LIKE :q", q: query_pattern)

    # 카테고리 필터 적용
    base_query = apply_category_filter(base_query)

    @posts = base_query.order(created_at: :desc).limit(limit)

    # 총 개수도 같은 필터 적용
    count_query = Post.published.where("title LIKE :q OR content LIKE :q", q: query_pattern)
    count_query = apply_category_filter(count_query)
    @posts_total_count = count_query.count
  end

  # 게시글 검색 (게시글 탭용 - 페이지네이션)
  def search_posts_paginated
    query_pattern = "%#{sanitize_like(@query)}%"

    base_query = Post.published
                     .includes(:user, images_attachments: :blob)
                     .where("title LIKE :q OR content LIKE :q", q: query_pattern)

    # 카테고리 필터 적용
    base_query = apply_category_filter(base_query)

    @posts_total_count = base_query.count
    @posts_total_pages = (@posts_total_count.to_f / POSTS_PER_PAGE).ceil
    @posts_page = [[@page, 1].max, [@posts_total_pages, 1].max].min

    offset = (@posts_page - 1) * POSTS_PER_PAGE
    @posts = base_query.order(created_at: :desc).offset(offset).limit(POSTS_PER_PAGE)
  end

  # 카테고리 필터 적용
  def apply_category_filter(query)
    case @category
    when "community"
      query.where(category: [:free, :question, :promotion])
    when "hiring"
      query.where(category: :hiring)
    when "seeking"
      query.where(category: :seeking)
    else
      query
    end
  end

  # SQL Injection 방지를 위한 LIKE 패턴 이스케이프
  def sanitize_like(query)
    query.gsub(/[%_\\]/) { |char| "\\#{char}" }
  end

  # 최근 검색어 저장 (쿠키 기반, 최대 10개)
  def save_recent_search
    recent = load_recent_searches
    recent.delete(@query) # 중복 제거
    recent.unshift(@query) # 맨 앞에 추가
    recent = recent.first(10) # 최대 10개

    cookies[:recent_searches] = {
      value: recent.to_json,
      expires: 30.days.from_now
    }
  end

  # 최근 검색어 로드
  def load_recent_searches
    return [] unless cookies[:recent_searches].present?

    JSON.parse(cookies[:recent_searches])
  rescue JSON::ParserError
    []
  end
end
