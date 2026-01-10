# frozen_string_literal: true

module Search
  # 최근 검색어 관리 서비스
  #
  # 쿠키 기반으로 최근 검색어를 저장/로드/삭제
  # 최대 10개까지 저장
  #
  # 사용 예:
  #   manager = Search::RecentSearchesManager.new(cookies)
  #   manager.save("창업")
  #   manager.all  # => ["창업", "개발자", ...]
  #   manager.delete("창업")
  #   manager.clear
  class RecentSearchesManager
    MAX_RECENT_SEARCHES = 10
    COOKIE_KEY = :recent_searches
    EXPIRY = 30.days

    attr_reader :cookies

    def initialize(cookies)
      @cookies = cookies
    end

    # 모든 최근 검색어 로드
    def all
      return [] unless cookies[COOKIE_KEY].present?

      JSON.parse(cookies[COOKIE_KEY])
    rescue JSON::ParserError
      []
    end

    # 검색어 저장 (중복 제거, 최대 10개)
    def save(query)
      return if query.blank?

      recent = all
      recent.delete(query)      # 중복 제거
      recent.unshift(query)     # 맨 앞에 추가
      recent = recent.first(MAX_RECENT_SEARCHES)

      write_cookie(recent)
    end

    # 특정 검색어 삭제
    def delete(query)
      recent = all
      recent.delete(query)
      write_cookie(recent)
    end

    # 전체 삭제
    def clear
      cookies.delete(COOKIE_KEY)
    end

    private

    def write_cookie(data)
      cookies[COOKIE_KEY] = {
        value: data.to_json,
        expires: EXPIRY.from_now
      }
    end
  end
end
