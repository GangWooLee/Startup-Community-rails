class SearchController < ApplicationController
  before_action :hide_floating_button

  # 검색 결과 제한
  USERS_LIMIT = 5
  POSTS_LIMIT = 20

  def index
    @query = params[:q].to_s.strip

    if @query.present? && @query.length >= 1
      search_users
      search_posts
    else
      @users = []
      @posts = []
      @users_total_count = 0
      @posts_total_count = 0
    end

    # 최근 검색어 저장 (로그인 사용자만)
    save_recent_search if logged_in? && @query.present?

    # 최근 검색어 로드
    @recent_searches = load_recent_searches
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

  # 사용자 검색: 이름, 역할, 소개에서 검색
  def search_users
    query_pattern = "%#{sanitize_like(@query)}%"

    @users = User.where(
      "name LIKE :q OR role_title LIKE :q OR bio LIKE :q OR affiliation LIKE :q",
      q: query_pattern
    ).order(created_at: :desc).limit(USERS_LIMIT)

    @users_total_count = User.where(
      "name LIKE :q OR role_title LIKE :q OR bio LIKE :q OR affiliation LIKE :q",
      q: query_pattern
    ).count
  end

  # 게시글 검색: 제목, 내용에서 검색
  def search_posts
    query_pattern = "%#{sanitize_like(@query)}%"

    @posts = Post.published
                 .includes(:user, images_attachments: :blob)
                 .where("title LIKE :q OR content LIKE :q", q: query_pattern)
                 .order(created_at: :desc)
                 .limit(POSTS_LIMIT)

    @posts_total_count = Post.published
                             .where("title LIKE :q OR content LIKE :q", q: query_pattern)
                             .count
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
