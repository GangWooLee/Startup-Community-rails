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
end
