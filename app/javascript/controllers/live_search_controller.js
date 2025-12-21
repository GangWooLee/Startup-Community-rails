import { Controller } from "@hotwired/stimulus"

// 실시간 검색 컨트롤러
// 사용자가 입력할 때마다 debounce를 적용하여 검색 결과를 동적으로 표시
export default class extends Controller {
  static targets = ["input", "results", "loading", "clearButton", "tabs", "categoryFilters"]
  static values = {
    url: String,
    debounceMs: { type: Number, default: 150 },
    tab: { type: String, default: "all" },
    category: { type: String, default: "all" },
    page: { type: Number, default: 1 }
  }

  connect() {
    this.abortController = null
    this.debounceTimer = null
  }

  disconnect() {
    this.cancelPendingRequest()
    this.clearDebounce()
  }

  // 입력 이벤트 핸들러 (debounce 적용)
  search() {
    this.clearDebounce()

    const query = this.inputTarget.value.trim()

    // X 버튼 표시/숨김
    this.toggleClearButton(query.length > 0)

    // 검색어 변경 시 페이지 초기화
    this.pageValue = 1

    // 빈 검색어면 결과 초기화
    if (query.length === 0) {
      this.showEmptyState()
      return
    }

    // Debounce 적용
    this.debounceTimer = setTimeout(() => {
      this.performSearch(query)
    }, this.debounceMsValue)
  }

  // 검색 실행
  async performSearch(query) {
    this.cancelPendingRequest()
    this.showLoading()

    try {
      this.abortController = new AbortController()

      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set('q', query)
      url.searchParams.set('live', 'true') // 실시간 검색 표시
      url.searchParams.set('tab', this.tabValue)
      url.searchParams.set('category', this.categoryValue)
      url.searchParams.set('page', this.pageValue)

      const response = await fetch(url, {
        headers: {
          'Accept': 'text/vnd.turbo-stream.html, text/html',
          'X-Requested-With': 'XMLHttpRequest'
        },
        signal: this.abortController.signal
      })

      if (response.ok) {
        const html = await response.text()

        // Turbo Stream 응답 처리
        if (response.headers.get('Content-Type')?.includes('turbo-stream')) {
          Turbo.renderStreamMessage(html)
        } else {
          // 일반 HTML 응답
          this.resultsTarget.innerHTML = html
        }
      }
    } catch (error) {
      if (error.name !== 'AbortError') {
        console.error('Search error:', error)
      }
    } finally {
      this.hideLoading()
    }
  }

  // 검색어 지우기
  clear() {
    this.inputTarget.value = ''
    this.inputTarget.focus()
    this.toggleClearButton(false)
    this.showEmptyState()

    // URL에서 검색어 파라미터 제거
    const url = new URL(window.location)
    url.searchParams.delete('q')
    history.replaceState({}, '', url)
  }

  // 빈 상태 표시 (최근 검색어 또는 가이드)
  showEmptyState() {
    // 서버에서 빈 상태 HTML 가져오기
    this.performSearch('')
  }

  // 로딩 표시
  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden')
    }
  }

  // 로딩 숨김
  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden')
    }
  }

  // X 버튼 표시/숨김
  toggleClearButton(show) {
    if (this.hasClearButtonTarget) {
      if (show) {
        this.clearButtonTarget.classList.remove('hidden')
      } else {
        this.clearButtonTarget.classList.add('hidden')
      }
    }
  }

  // 진행 중인 요청 취소
  cancelPendingRequest() {
    if (this.abortController) {
      this.abortController.abort()
      this.abortController = null
    }
  }

  // Debounce 타이머 정리
  clearDebounce() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = null
    }
  }

  // 엔터키 방지 (폼 제출 대신 실시간 검색)
  preventSubmit(event) {
    event.preventDefault()
  }

  // 탭 전환
  switchTab(event) {
    const newTab = event.currentTarget.dataset.tab
    this.tabValue = newTab

    // 탭 버튼 스타일 업데이트
    this.updateTabStyles(newTab)

    // 카테고리 필터 표시/숨김
    this.toggleCategoryFilters(newTab === 'posts')

    // 탭 변경 시 카테고리 및 페이지 초기화
    if (newTab !== 'posts') {
      this.categoryValue = 'all'
    }
    this.pageValue = 1

    // 검색 재실행
    const query = this.inputTarget.value.trim()
    this.performSearch(query)

    // URL 업데이트
    this.updateUrl()
  }

  // 카테고리 전환
  switchCategory(event) {
    const newCategory = event.currentTarget.dataset.category
    this.categoryValue = newCategory
    this.pageValue = 1  // 카테고리 변경 시 페이지 초기화

    // 카테고리 버튼 스타일 업데이트
    this.updateCategoryStyles(newCategory)

    // 검색 재실행
    const query = this.inputTarget.value.trim()
    this.performSearch(query)

    // URL 업데이트
    this.updateUrl()
  }

  // 이전 페이지
  prevPage() {
    if (this.pageValue > 1) {
      this.pageValue--
      this.performSearch(this.inputTarget.value.trim())
      this.updateUrl()
    }
  }

  // 다음 페이지
  nextPage() {
    this.pageValue++
    this.performSearch(this.inputTarget.value.trim())
    this.updateUrl()
  }

  // 특정 페이지로 이동
  goToPage(event) {
    const page = parseInt(event.currentTarget.dataset.page, 10)
    if (page && page !== this.pageValue) {
      this.pageValue = page
      this.performSearch(this.inputTarget.value.trim())
      this.updateUrl()
    }
  }

  // 탭 버튼 스타일 업데이트
  updateTabStyles(activeTab) {
    if (!this.hasTabsTarget) return

    this.tabsTarget.querySelectorAll('button').forEach(btn => {
      const isActive = btn.dataset.tab === activeTab
      btn.className = `px-4 py-1.5 rounded-full text-sm font-medium transition-colors ${
        isActive
          ? 'bg-primary text-primary-foreground'
          : 'bg-secondary text-muted-foreground hover:text-foreground'
      }`
    })
  }

  // 카테고리 버튼 스타일 업데이트
  updateCategoryStyles(activeCategory) {
    if (!this.hasCategoryFiltersTarget) return

    this.categoryFiltersTarget.querySelectorAll('button').forEach(btn => {
      const isActive = btn.dataset.category === activeCategory
      btn.className = `px-3 py-1 rounded-full text-xs font-medium transition-colors ${
        isActive
          ? 'bg-foreground text-background'
          : 'bg-muted text-muted-foreground hover:text-foreground'
      }`
    })
  }

  // 카테고리 필터 표시/숨김
  toggleCategoryFilters(show) {
    if (!this.hasCategoryFiltersTarget) return

    if (show) {
      this.categoryFiltersTarget.classList.remove('hidden')
    } else {
      this.categoryFiltersTarget.classList.add('hidden')
    }
  }

  // URL 업데이트 (브라우저 히스토리)
  updateUrl() {
    const url = new URL(window.location)
    url.searchParams.set('tab', this.tabValue)

    if (this.tabValue === 'posts' && this.categoryValue !== 'all') {
      url.searchParams.set('category', this.categoryValue)
    } else {
      url.searchParams.delete('category')
    }

    if (this.tabValue === 'users' && this.pageValue > 1) {
      url.searchParams.set('page', this.pageValue)
    } else {
      url.searchParams.delete('page')
    }

    history.replaceState({}, '', url)
  }
}
