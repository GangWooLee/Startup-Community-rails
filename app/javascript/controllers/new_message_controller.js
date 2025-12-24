import { Controller } from "@hotwired/stimulus"

// 새 메시지 작성 컨트롤러
export default class extends Controller {
  static targets = [
    "searchInput",
    "searchContainer",
    "searchResults",
    "selectedRecipient",
    "selectedName",
    "recipientId",
    "composeArea",
    "selectPrompt",
    "messageInput",
    "submitButton",
    "form"
  ]

  connect() {
    this.searchTimeout = null
    this.selectedUserId = null

    // 검색 결과 클릭 이벤트 위임 처리
    this.handleSearchResultClick = this.handleSearchResultClick.bind(this)
    this.searchResultsTarget.addEventListener("click", this.handleSearchResultClick)

    // 외부 클릭 시 검색 결과 닫기
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  disconnect() {
    this.searchResultsTarget.removeEventListener("click", this.handleSearchResultClick)
    document.removeEventListener("click", this.handleClickOutside)
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }
  }

  handleClickOutside(event) {
    // 검색 결과 영역 내부 클릭은 무시
    if (this.searchResultsTarget.contains(event.target)) {
      return
    }
    // 검색 입력 영역 클릭도 무시
    if (this.hasSearchContainerTarget && this.searchContainerTarget.contains(event.target)) {
      return
    }
    this.hideSearchResults()
  }

  // 검색 결과 클릭 이벤트 위임 처리
  handleSearchResultClick(event) {
    const button = event.target.closest("[data-user-id]")
    if (button) {
      event.preventDefault()
      event.stopPropagation()
      this.selectRecipientFromButton(button)
    }
  }

  search() {
    // ★ 이미 선택된 상태면 검색 자체를 하지 않음
    if (this.selectedUserId) {
      return
    }

    const query = this.searchInputTarget.value.trim()

    // 디바운스 처리
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }

    if (query.length < 1) {
      this.hideSearchResults()
      return
    }

    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    // 이미 선택된 상태면 검색 무시
    if (this.selectedUserId) {
      return
    }

    try {
      const response = await fetch(`/chat_rooms/search_users?query=${encodeURIComponent(query)}`, {
        headers: {
          "Accept": "application/json",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (!response.ok) throw new Error("Search failed")

      const users = await response.json()
      this.displaySearchResults(users)
    } catch (error) {
      console.error("Search error:", error)
      this.searchResultsTarget.innerHTML = `
        <div class="px-4 py-3 text-sm text-gray-500 text-center">
          검색 중 오류가 발생했습니다
        </div>
      `
      this.showSearchResults()
    }
  }

  displaySearchResults(users) {
    // ★ 이미 선택된 상태면 검색 결과 표시하지 않음
    if (this.selectedUserId) {
      return
    }

    if (users.length === 0) {
      this.searchResultsTarget.innerHTML = `
        <div class="px-4 py-3 text-sm text-gray-500 text-center">
          검색 결과가 없습니다
        </div>
      `
    } else {
      // 이벤트 위임으로 처리하므로 data-action 제거 (중복 실행 방지)
      this.searchResultsTarget.innerHTML = users.map(user => `
        <button type="button"
                class="w-full flex items-center gap-3 px-4 py-3 hover:bg-gray-50 transition-colors text-left cursor-pointer"
                data-user-id="${user.id}"
                data-user-name="${this.escapeHtml(user.name)}"
                data-user-role="${this.escapeHtml(user.role_title || '')}">
          ${user.avatar_url
            ? `<img src="${user.avatar_url}" class="w-10 h-10 rounded-full object-cover border border-gray-200" alt="${this.escapeHtml(user.name)}">`
            : `<div class="w-10 h-10 rounded-full bg-gradient-to-br from-primary to-primary/70 flex items-center justify-center text-white font-semibold">
                 ${user.name ? user.name.charAt(0).toUpperCase() : '?'}
               </div>`
          }
          <div class="flex-1 min-w-0">
            <p class="font-medium text-gray-900 truncate">${this.escapeHtml(user.name)}</p>
            ${user.role_title ? `<p class="text-xs text-gray-500 truncate">${this.escapeHtml(user.role_title)}</p>` : ''}
          </div>
        </button>
      `).join('')
    }

    this.showSearchResults()
  }

  // 검색 결과에서 사용자 선택 (이벤트 위임으로만 호출됨)
  selectRecipientFromButton(button) {
    // 이미 선택된 상태면 무시 (중복 호출 방지)
    if (this.selectedUserId) {
      return
    }

    const userId = button.dataset.userId
    const userName = button.dataset.userName

    if (!userId || !userName) {
      return
    }

    // ★ 핵심: 대기 중인 검색 타이머 취소 (선택 후 검색창 다시 뜨는 버그 방지)
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
      this.searchTimeout = null
    }

    // 선택된 사용자 정보 저장
    this.selectedUserId = userId
    this.recipientIdTarget.value = userId
    this.selectedNameTarget.textContent = userName

    // UI 전환
    this.searchContainerTarget.classList.add("hidden")
    this.selectedRecipientTarget.classList.remove("hidden")
    this.selectPromptTarget.classList.add("hidden")
    this.composeAreaTarget.classList.remove("hidden")

    // 검색 결과 숨기기
    this.hideSearchResults()
    this.searchInputTarget.value = ""

    // 메시지 입력에 포커스
    setTimeout(() => {
      this.messageInputTarget.focus()
    }, 100)
  }

  clearRecipient() {
    // 선택 초기화
    this.selectedUserId = null
    this.recipientIdTarget.value = ""
    this.selectedNameTarget.textContent = ""

    // UI 전환
    this.selectedRecipientTarget.classList.add("hidden")
    this.searchContainerTarget.classList.remove("hidden")
    this.composeAreaTarget.classList.add("hidden")
    this.selectPromptTarget.classList.remove("hidden")

    // 검색 입력에 포커스
    this.searchInputTarget.focus()

    // 전송 버튼 비활성화
    this.submitButtonTarget.disabled = true
  }

  showSearchResults() {
    // ★ 최종 방어: 선택 완료 상태에서는 절대 검색 결과를 표시하지 않음
    if (this.selectedUserId) {
      return
    }
    this.searchResultsTarget.classList.remove("hidden")
  }

  hideSearchResults() {
    this.searchResultsTarget.classList.add("hidden")
  }

  autoResize() {
    const textarea = this.messageInputTarget
    textarea.style.height = "auto"
    textarea.style.height = Math.min(textarea.scrollHeight, 120) + "px"

    // 메시지가 있으면 전송 버튼 활성화
    this.submitButtonTarget.disabled = textarea.value.trim().length === 0
  }

  handleKeydown(event) {
    // Shift + Enter는 줄바꿈, Enter만 누르면 전송
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      if (!this.submitButtonTarget.disabled) {
        this.formTarget.requestSubmit()
      }
    }
  }

  sendMessage(event) {
    // 수신자가 선택되지 않았으면 전송 방지
    if (!this.selectedUserId) {
      event.preventDefault()
      alert("메시지를 보낼 대상을 선택해주세요.")
      return
    }

    // 메시지가 비어있으면 전송 방지
    if (this.messageInputTarget.value.trim().length === 0) {
      event.preventDefault()
      return
    }

    // 폼 제출 허용 (기본 동작)
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
