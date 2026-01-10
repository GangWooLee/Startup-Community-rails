# frozen_string_literal: true

# 검색 컨트롤러
#
# 사용자 및 게시글 검색, 최근 검색어 관리
# 실시간 검색, 모달 검색, Drill-down 지원
class SearchController < ApplicationController
  before_action :hide_floating_button

  # 검색 결과 제한
  USERS_LIMIT = 5
  USERS_PER_PAGE = 10
  POSTS_LIMIT = 5
  POSTS_PER_PAGE = 10

  # 탭 및 카테고리
  TABS = %w[all users posts].freeze
  POST_CATEGORIES = %w[all community hiring seeking].freeze

  # ==========================================================================
  # Actions
  # ==========================================================================

  def index
    parse_params
    execute_search if @query.present? && @query.length >= 1
    save_search_if_needed
    @recent_searches = recent_searches_manager.all

    respond_to do |format|
      format.html { render_html_response }
      format.turbo_stream { render_turbo_stream_response }
    end
  end

  def destroy_recent
    recent_searches_manager.delete(params[:query])
    redirect_to search_path, status: :see_other
  end

  def clear_recent
    recent_searches_manager.clear
    redirect_to search_path, status: :see_other
  end

  private

  # ==========================================================================
  # Params & Initialization
  # ==========================================================================

  def parse_params
    @query = params[:q].to_s.strip
    @tab = TABS.include?(params[:tab]) ? params[:tab] : "all"
    @category = POST_CATEGORIES.include?(params[:category]) ? params[:category] : "all"
    @page = (params[:page] || 1).to_i
    initialize_empty_results
  end

  def initialize_empty_results
    @users = []
    @posts = []
    @users_total_count = 0
    @posts_total_count = 0
    @users_page = 1
    @users_total_pages = 0
    @posts_page = 1
    @posts_total_pages = 0
  end

  # ==========================================================================
  # Search Execution
  # ==========================================================================

  def query_executor
    @query_executor ||= Search::QueryExecutor.new(query: @query, category: @category)
  end

  def execute_search
    case @tab
    when "users"
      execute_users_search
    when "posts"
      execute_posts_search
    else
      execute_all_search
    end
  end

  def execute_users_search
    result = query_executor.search_users_paginated(page: @page, per_page: USERS_PER_PAGE)
    @users = result.items
    @users_total_count = result.total_count
    @users_page = result.page
    @users_total_pages = result.total_pages
  end

  def execute_posts_search
    result = query_executor.search_posts_paginated(page: @page, per_page: POSTS_PER_PAGE)
    @posts = result.items
    @posts_total_count = result.total_count
    @posts_page = result.page
    @posts_total_pages = result.total_pages
  end

  def execute_all_search
    users_result = query_executor.search_users(limit: USERS_LIMIT)
    posts_result = query_executor.search_posts(limit: POSTS_LIMIT)

    @users = users_result.items
    @users_total_count = users_result.total_count
    @posts = posts_result.items
    @posts_total_count = posts_result.total_count
  end

  # ==========================================================================
  # Recent Searches
  # ==========================================================================

  def recent_searches_manager
    @recent_searches_manager ||= Search::RecentSearchesManager.new(cookies)
  end

  def save_search_if_needed
    return unless logged_in? && @query.present? && !live_search_request?

    recent_searches_manager.save(@query)
    track_ga4_event("search", { search_term: @query.truncate(100), tab: @tab })
  end

  # ==========================================================================
  # Request Type Detection
  # ==========================================================================

  def live_search_request?
    request.xhr? || params[:live] == "true"
  end

  def modal_search_request?
    params[:modal] == "true"
  end

  def drilldown_request?
    params[:modal] == "true" && params[:drilldown] == "true"
  end

  def drilldown_append_request?
    drilldown_request? && params[:append] == "true"
  end

  # ==========================================================================
  # Response Rendering
  # ==========================================================================

  def render_html_response
    if drilldown_request?
      render partial: "search/modal_drilldown", locals: drilldown_locals, layout: false
    elsif modal_search_request?
      render partial: "search/modal_results", locals: modal_result_locals, layout: false
    elsif live_search_request?
      render partial: "search/results", locals: result_locals, layout: false
    else
      render :index
    end
  end

  def render_turbo_stream_response
    return unless drilldown_append_request?

    items = @tab == "users" ? @users : @posts
    total_pages = @tab == "users" ? @users_total_pages : @posts_total_pages
    total_count = @tab == "users" ? @users_total_count : @posts_total_count
    has_more = @page < total_pages

    render turbo_stream: build_drilldown_streams(items, total_count, has_more)
  end

  def build_drilldown_streams(items, total_count, has_more)
    streams = [
      turbo_stream.append(
        "drilldown_items_#{@tab}",
        partial: "search/drilldown_items",
        locals: { drilldown_type: @tab, items: items }
      )
    ]

    streams << if has_more
                 turbo_stream.replace(
                   "drilldown_load_more",
                   partial: "search/drilldown_load_more",
                   locals: { query: @query, drilldown_type: @tab, next_page: @page + 1, total_count: total_count }
                 )
    else
                 turbo_stream.remove("drilldown_load_more")
    end

    streams.compact
  end

  # ==========================================================================
  # View Locals
  # ==========================================================================

  def result_locals
    {
      query: @query, tab: @tab, category: @category,
      users: @users, posts: @posts,
      users_total_count: @users_total_count, posts_total_count: @posts_total_count,
      users_page: @users_page, users_total_pages: @users_total_pages,
      posts_page: @posts_page, posts_total_pages: @posts_total_pages,
      recent_searches: @recent_searches
    }
  end

  def modal_result_locals
    {
      query: @query,
      users: @users.first(3),
      posts: @posts.first(5),
      users_total_count: @users_total_count,
      posts_total_count: @posts_total_count
    }
  end

  def drilldown_locals
    {
      query: @query,
      drilldown_type: @tab,
      items: @tab == "users" ? @users : @posts,
      total_count: @tab == "users" ? @users_total_count : @posts_total_count,
      current_page: @page,
      has_more_pages: @tab == "users" ? @users_page < @users_total_pages : @posts_page < @posts_total_pages,
      next_page: @page + 1
    }
  end
end
