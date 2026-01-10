# frozen_string_literal: true

# 페이지네이션 헬퍼
#
# 페이지 번호 범위 계산 및 표시 로직 제공
module PaginationHelper
  # 페이지네이션 범위 계산 (1 2 3 ... 10 형태)
  # @param current_page [Integer] 현재 페이지
  # @param total_pages [Integer] 전체 페이지 수
  # @return [Array] 페이지 번호 배열 (... 은 :ellipsis로 표시)
  def pagination_range(current_page, total_pages)
    return [] if total_pages <= 0
    return [ 1 ] if total_pages == 1

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
        pages.concat((2..[ 4, total_pages - 1 ].min).to_a)
        pages << :ellipsis if total_pages > 5
      elsif current_page >= total_pages - 2
        # 뒤쪽에 있을 때: 1 ... 7 8 9 10
        pages << :ellipsis if total_pages > 5
        pages.concat(([ total_pages - 3, 2 ].max..total_pages - 1).to_a)
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
