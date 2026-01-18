# frozen_string_literal: true

module Search
  # 검색 쿼리 실행 서비스
  #
  # 사용자 및 게시글 검색을 담당
  # SQL Injection 방지 및 페이지네이션 지원
  #
  # 사용 예:
  #   executor = Search::QueryExecutor.new(query: "창업", category: "all")
  #   result = executor.search_users(limit: 5)
  #   result = executor.search_users_paginated(page: 1, per_page: 10)
  class QueryExecutor
    attr_reader :query, :category

    def initialize(query:, category: "all")
      @query = query.to_s.strip
      @category = category
    end

    # ==========================================================================
    # 사용자 검색
    # ==========================================================================

    # 사용자 검색 (제한된 수만)
    def search_users(limit:)
      base = users_base_query
      Result.new(
        items: base.order(created_at: :desc).limit(limit),
        total_count: base.count,
        page: 1,
        total_pages: 0
      )
    end

    # 사용자 검색 (페이지네이션)
    def search_users_paginated(page:, per_page:)
      base = users_base_query
      total_count = base.count
      total_pages = (total_count.to_f / per_page).ceil
      current_page = [ [ page, 1 ].max, [ total_pages, 1 ].max ].min
      offset = (current_page - 1) * per_page

      Result.new(
        items: base.order(created_at: :desc).offset(offset).limit(per_page),
        total_count: total_count,
        page: current_page,
        total_pages: total_pages
      )
    end

    # ==========================================================================
    # 게시글 검색
    # ==========================================================================

    # 게시글 검색 (제한된 수만)
    def search_posts(limit:)
      base = posts_base_query
      Result.new(
        items: base.includes(user: { avatar_attachment: :blob }, images_attachments: :blob)
                   .order(created_at: :desc)
                   .limit(limit),
        total_count: base.count,
        page: 1,
        total_pages: 0
      )
    end

    # 게시글 검색 (페이지네이션)
    def search_posts_paginated(page:, per_page:)
      base = posts_base_query.includes(user: { avatar_attachment: :blob }, images_attachments: :blob)
      total_count = base.count
      total_pages = (total_count.to_f / per_page).ceil
      current_page = [ [ page, 1 ].max, [ total_pages, 1 ].max ].min
      offset = (current_page - 1) * per_page

      Result.new(
        items: base.order(created_at: :desc).offset(offset).limit(per_page),
        total_count: total_count,
        page: current_page,
        total_pages: total_pages
      )
    end

    private

    def query_pattern
      @query_pattern ||= "%#{sanitize_like(query)}%"
    end

    def users_base_query
      User.includes(avatar_attachment: :blob)
          .where(
            "name LIKE :q OR role_title LIKE :q OR bio LIKE :q OR affiliation LIKE :q",
            q: query_pattern
          )
    end

    def posts_base_query
      base = Post.published
                 .where("title LIKE :q OR content LIKE :q", q: query_pattern)
      apply_category_filter(base)
    end

    def apply_category_filter(query)
      case category
      when "community"
        query.where(category: [ :free, :question, :promotion ])
      when "hiring"
        query.where(category: :hiring)
      when "seeking"
        query.where(category: :seeking)
      else
        query
      end
    end

    # SQL Injection 방지를 위한 LIKE 패턴 이스케이프
    def sanitize_like(value)
      value.gsub(/[%_\\]/) { |char| "\\#{char}" }
    end

    # 검색 결과 객체
    class Result
      attr_reader :items, :total_count, :page, :total_pages

      def initialize(items:, total_count:, page:, total_pages:)
        @items = items
        @total_count = total_count
        @page = page
        @total_pages = total_pages
      end

      def has_more_pages?
        page < total_pages
      end
    end
  end
end
