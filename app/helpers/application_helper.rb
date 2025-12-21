module ApplicationHelper
  # 검색어를 하이라이팅하여 표시
  # text: 원본 텍스트
  # query: 검색어
  # 반환: 검색어 부분이 <mark>로 감싸진 HTML safe 문자열
  def highlight_search(text, query)
    return "" if text.blank?
    return h(text) if query.blank?

    # 대소문자 무시하고 검색어 찾기
    escaped_query = Regexp.escape(query)
    regex = /(#{escaped_query})/i

    # 검색어를 <mark> 태그로 감싸기
    highlighted = h(text).gsub(regex) do |match|
      "<mark class=\"bg-yellow-200 text-foreground px-0.5 rounded\">#{match}</mark>"
    end

    highlighted.html_safe
  end

  # 텍스트를 검색어 주변으로 잘라서 하이라이팅
  # text: 원본 텍스트
  # query: 검색어
  # max_length: 최대 길이
  def highlight_snippet(text, query, max_length: 100)
    return "" if text.blank?
    return h(text.truncate(max_length)) if query.blank?

    # 검색어 위치 찾기
    query_pos = text.downcase.index(query.downcase)

    if query_pos
      # 검색어 앞뒤로 텍스트 추출
      start_pos = [query_pos - 30, 0].max
      end_pos = [query_pos + query.length + 70, text.length].min

      snippet = text[start_pos...end_pos]
      snippet = "..." + snippet if start_pos > 0
      snippet = snippet + "..." if end_pos < text.length

      highlight_search(snippet, query)
    else
      highlight_search(text.truncate(max_length), query)
    end
  end

  # 페이지네이션 범위 계산 (1 2 3 ... 10 형태)
  # current_page: 현재 페이지
  # total_pages: 전체 페이지 수
  # 반환: 페이지 번호 배열 (... 은 :ellipsis로 표시)
  def pagination_range(current_page, total_pages)
    return [] if total_pages <= 0
    return [1] if total_pages == 1

    # 표시할 최대 페이지 수
    max_visible = 5

    if total_pages <= max_visible
      # 전체 페이지가 적으면 모두 표시
      (1..total_pages).to_a
    else
      pages = []

      # 항상 첫 페이지 표시
      pages << 1

      # 현재 페이지 주변 계산
      if current_page <= 3
        # 앞쪽에 있을 때: 1 2 3 4 ... 10
        pages.concat((2..[4, total_pages - 1].min).to_a)
        pages << :ellipsis if total_pages > 5
      elsif current_page >= total_pages - 2
        # 뒤쪽에 있을 때: 1 ... 7 8 9 10
        pages << :ellipsis if total_pages > 5
        pages.concat(([total_pages - 3, 2].max..total_pages - 1).to_a)
      else
        # 중간에 있을 때: 1 ... 5 6 7 ... 10
        pages << :ellipsis
        pages.concat((current_page - 1..current_page + 1).to_a)
        pages << :ellipsis
      end

      # 항상 마지막 페이지 표시
      pages << total_pages

      pages.uniq
    end
  end
end
