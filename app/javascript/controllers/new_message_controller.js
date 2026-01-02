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

  // Stimulus Values - 프로필에서 대화하기 클릭 시 미리 선택된 수신자 정보
  static values = {
    preselectedId: String,
    preselectedName: String
  }

  connect() {
    this.searchTimeout = null
    this.selectedUserId = null
    this.currentSearchId = 0  // 검색 요청 ID (비동기 요청 취소용)
    // 디버그 모드: development 환경에서만 활성화
    this.debugMode = document.documentElement.dataset.environment === "development"
    this.isSelectingUser = false  // ★ 사용자 선택 중 플래그 (blur 방지용)
    this.blurTimeout = null  // ★ blur 타이머 추적용

    // 외부 클릭 시 검색 결과 닫기
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)

    // ★ 검색 결과 영역에 이벤트 위임 설정 (mousedown 캡처)
    // 이렇게 하면 내부 버튼이 변경되어도 이벤트가 확실히 잡힘
    this.handleResultsMousedown = this.handleResultsMousedown.bind(this)
    this.searchResultsTarget.addEventListener("mousedown", this.handleResultsMousedown, true)

    // ★ 마우스가 검색 결과 위에 있으면 검색 결과 업데이트 방지
    this.handleResultsMouseenter = this.handleResultsMouseenter.bind(this)
    this.handleResultsMouseleave = this.handleResultsMouseleave.bind(this)
    this.searchResultsTarget.addEventListener("mouseenter", this.handleResultsMouseenter)
    this.searchResultsTarget.addEventListener("mouseleave", this.handleResultsMouseleave)
    this.isHoveringResults = false

    // ★ 검색 입력창 blur 시 검색 결과 숨기기 (단, 사용자 선택 중이 아닐 때만)
    this.handleSearchBlur = this.handleSearchBlur.bind(this)
    this.searchInputTarget.addEventListener("blur", this.handleSearchBlur)

    // 미리 선택된 수신자가 있으면 자동 선택
    if (this.hasPreselectedIdValue && this.preselectedIdValue) {
      this.preselectRecipient(this.preselectedIdValue, this.preselectedNameValue)
    }

    this.log("Controller connected")
  }

  log(...args) {
    if (this.debugMode) {
      console.log("[NewMessage]", ...args)
    }
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
    this.searchResultsTarget.removeEventListener("mousedown", this.handleResultsMousedown, true)
    this.searchResultsTarget.removeEventListener("mouseenter", this.handleResultsMouseenter)
    this.searchResultsTarget.removeEventListener("mouseleave", this.handleResultsMouseleave)
    this.searchInputTarget.removeEventListener("blur", this.handleSearchBlur)
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }
    if (this.blurTimeout) {
      clearTimeout(this.blurTimeout)
    }
  }

  // ★ 마우스가 검색 결과 위에 진입
  handleResultsMouseenter(event) {
    this.log("handleResultsMouseenter - mouse entered results")
    this.isHoveringResults = true
  }

  // ★ 마우스가 검색 결과에서 나감
  handleResultsMouseleave(event) {
    // relatedTarget이 여전히 searchResults 안에 있으면 실제로 나간 게 아님
    if (event.relatedTarget && this.searchResultsTarget.contains(event.relatedTarget)) {
      this.log("handleResultsMouseleave - still inside results, ignoring")
      return
    }
    this.log("handleResultsMouseleave - mouse left results")
    this.isHoveringResults = false
  }

  // ★ 검색 입력창 blur 핸들러 - 사용자 선택 중이면 blur 무시
  handleSearchBlur(event) {
    this.log("handleSearchBlur called", {
      isSelectingUser: this.isSelectingUser,
      selectedUserId: this.selectedUserId
    })

    // 사용자 선택 중이면 blur 시 검색 결과 숨기지 않음
    if (this.isSelectingUser || this.selectedUserId) {
      this.log("handleSearchBlur - ignoring blur during selection")
      return
    }

    // 기존 blur 타이머 취소
    if (this.blurTimeout) {
      clearTimeout(this.blurTimeout)
      this.blurTimeout = null
    }

    // 약간의 딜레이 후 검색 결과 숨기기 (다른 요소 클릭 시간 허용)
    this.blurTimeout = setTimeout(() => {
      this.blurTimeout = null
      if (!this.isSelectingUser && !this.selectedUserId) {
        this.hideSearchResults()
      }
    }, 150)
  }

  // ★ 검색 결과 영역 전체에서 mousedown 감지 (이벤트 위임)
  handleResultsMousedown(event) {
    this.log("handleResultsMousedown - captured at results container", {
      target: event.target.tagName,
      selectedUserId: this.selectedUserId
    })

    // 이미 선택된 상태면 무시
    if (this.selectedUserId) {
      this.log("handleResultsMousedown - already selected, ignoring")
      return
    }

    // 버튼 또는 버튼 내부 요소 찾기
    const button = event.target.closest("button[data-user-id]")
    if (!button) {
      this.log("handleResultsMousedown - no button found")
      return
    }

    const userId = button.dataset.userId
    const userName = button.dataset.userName

    if (!userId || !userName) {
      this.log("handleResultsMousedown - invalid data", { userId, userName })
      return
    }

    this.log("handleResultsMousedown - found user button", { userId, userName })

    // ★ 사용자 선택 시작 플래그 설정 (blur 이벤트가 검색 결과를 숨기지 않도록)
    this.isSelectingUser = true

    // 즉시 이벤트 전파 중단
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()

    // 검색 관련 모든 것 즉시 중단
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
      this.searchTimeout = null
    }
    // ★ blur 타이머도 취소
    if (this.blurTimeout) {
      clearTimeout(this.blurTimeout)
      this.blurTimeout = null
    }
    this.currentSearchId++

    // 즉시 선택 완료 처리
    this.completeSelection(userId, userName)
  }

  handleClickOutside(event) {
    // 이미 선택 완료 상태면 무시
    if (this.selectedUserId) {
      return
    }
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

  search() {
    // 스택 트레이스로 어디서 호출되었는지 확인
    this.log("search() called", {
      selectedUserId: this.selectedUserId,
      query: this.searchInputTarget.value,
      isHoveringResults: this.isHoveringResults,
      isSelectingUser: this.isSelectingUser,
      caller: new Error().stack?.split('\n')[2]?.trim()
    })

    // 이미 선택된 상태면 검색 자체를 하지 않음
    if (this.selectedUserId) {
      this.log("search() BLOCKED - already selected, selectedUserId:", this.selectedUserId)
      if (this.searchTimeout) {
        clearTimeout(this.searchTimeout)
        this.searchTimeout = null
      }
      return
    }

    // ★ 마우스가 검색 결과 위에 있거나 선택 중이면 검색하지 않음
    if (this.isHoveringResults || this.isSelectingUser) {
      this.log("search() BLOCKED - user is hovering or selecting")
      if (this.searchTimeout) {
        clearTimeout(this.searchTimeout)
        this.searchTimeout = null
      }
      return
    }

    const query = this.searchInputTarget.value.trim()

    // 디바운스 처리: 새 입력이 있으면 기존 타이머 취소
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
      this.searchTimeout = null
    }

    if (query.length < 1) {
      this.hideSearchResults()
      return
    }

    this.log("search() setting timeout for query:", query)
    this.searchTimeout = setTimeout(() => {
      // 타이머 실행 시점에도 다시 한번 체크
      if (this.selectedUserId || this.isHoveringResults || this.isSelectingUser) {
        this.log("search() timeout blocked - already selected or hovering")
        return
      }
      this.log("search() timeout executing for query:", query)
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    // 새 검색 ID 생성 (이전 검색 결과 무시용)
    const searchId = ++this.currentSearchId
    this.log("performSearch() called", { query, selectedUserId: this.selectedUserId, searchId })

    // 이미 선택된 상태면 검색 무시
    if (this.selectedUserId) {
      this.log("performSearch() blocked - already selected")
      return
    }

    try {
      const response = await fetch(`/chat_rooms/search_users?query=${encodeURIComponent(query)}`, {
        headers: {
          "Accept": "application/json",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      // 비동기 응답 후 체크: 선택됐거나 새로운 검색이 시작됐으면 무시
      if (this.selectedUserId || searchId !== this.currentSearchId) {
        this.log("performSearch() response ignored", {
          selectedUserId: this.selectedUserId,
          searchId,
          currentSearchId: this.currentSearchId
        })
        return
      }

      if (!response.ok) throw new Error("Search failed")

      const users = await response.json()

      // JSON 파싱 후에도 다시 체크
      if (this.selectedUserId || searchId !== this.currentSearchId) {
        this.log("performSearch() after JSON parse ignored")
        return
      }

      this.displaySearchResults(users)
    } catch (error) {
      if (this.selectedUserId) {
        return
      }
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
    this.log("displaySearchResults() called", {
      usersCount: users.length,
      selectedUserId: this.selectedUserId,
      isHoveringResults: this.isHoveringResults,
      isSelectingUser: this.isSelectingUser
    })

    // 이미 선택된 상태면 검색 결과 표시하지 않음
    if (this.selectedUserId) {
      this.log("displaySearchResults() blocked - already selected")
      return
    }

    // ★ 마우스가 검색 결과 위에 있거나 선택 중이면 업데이트하지 않음
    // 이렇게 하면 클릭 중에 innerHTML이 변경되어 클릭이 취소되는 것을 방지
    if (this.isHoveringResults || this.isSelectingUser) {
      this.log("displaySearchResults() blocked - user is hovering or selecting")
      return
    }

    if (users.length === 0) {
      this.searchResultsTarget.innerHTML = `
        <div class="px-4 py-3 text-sm text-gray-500 text-center">
          검색 결과가 없습니다
        </div>
      `
    } else {
      // 버튼에 data-action 없음 - 부모 요소에서 이벤트 위임으로 처리
      this.searchResultsTarget.innerHTML = users.map(user => `
        <button type="button"
                class="w-full flex items-center gap-3 px-4 py-3 hover:bg-gray-50 transition-colors text-left cursor-pointer"
                data-user-id="${user.id}"
                data-user-name="${this.escapeHtml(user.name)}"
                data-user-role="${this.escapeHtml(user.role_title || '')}">
          ${user.avatar_url && this.validateImageUrl(user.avatar_url)
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

  // 선택 완료 처리
  completeSelection(userId, userName) {
    this.log("completeSelection() called", { userId, userName, currentSelectedUserId: this.selectedUserId })

    // 이미 선택된 상태면 무시
    if (this.selectedUserId) {
      this.log("completeSelection() blocked - already selected")
      return
    }

    // ★ 가장 먼저 selectedUserId 설정 (다른 모든 작업 차단)
    this.selectedUserId = userId
    this.log("selectedUserId set to:", this.selectedUserId)

    // 선택된 사용자 정보 저장
    this.recipientIdTarget.value = userId
    this.selectedNameTarget.textContent = userName

    // 검색 결과 숨기고 비우기
    this.hideSearchResults()
    this.searchResultsTarget.innerHTML = ""
    this.searchInputTarget.value = ""
    this.isHoveringResults = false  // ★ hover 플래그도 리셋

    // UI 전환
    this.searchContainerTarget.classList.add("hidden")
    this.selectedRecipientTarget.classList.remove("hidden")
    this.selectPromptTarget.classList.add("hidden")
    this.composeAreaTarget.classList.remove("hidden")

    this.log("User selection complete, UI updated")

    // 메시지 입력에 포커스
    setTimeout(() => {
      this.messageInputTarget.focus()
    }, 100)
  }

  clearRecipient() {
    // 선택 초기화
    this.selectedUserId = null
    this.isSelectingUser = false  // ★ 선택 플래그도 초기화
    this.isHoveringResults = false  // ★ hover 플래그도 초기화
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

  // 미리 선택된 수신자 설정 (프로필에서 대화하기 클릭 시)
  preselectRecipient(userId, userName) {
    if (!userId || !userName) {
      return
    }

    // 선택된 사용자 정보 저장
    this.selectedUserId = userId
    this.recipientIdTarget.value = userId
    this.selectedNameTarget.textContent = userName

    // UI 전환: 검색창 숨기고 선택된 사용자 표시
    this.searchContainerTarget.classList.add("hidden")
    this.selectedRecipientTarget.classList.remove("hidden")
    this.selectPromptTarget.classList.add("hidden")
    this.composeAreaTarget.classList.remove("hidden")

    // 메시지 입력에 포커스
    setTimeout(() => {
      this.messageInputTarget.focus()
    }, 100)
  }

  showSearchResults() {
    this.log("showSearchResults() called", { selectedUserId: this.selectedUserId })

    // 선택 완료 상태에서는 검색 결과를 표시하지 않음
    if (this.selectedUserId) {
      this.log("showSearchResults() blocked - already selected")
      return
    }

    this.log("showSearchResults() showing results")
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

  // XSS 방지: 이미지 URL 검증
  validateImageUrl(url) {
    if (!url) return false

    try {
      const parsed = new URL(url, window.location.origin)
      // http 또는 https 프로토콜만 허용 (javascript:, data: 등 차단)
      return parsed.protocol === 'http:' || parsed.protocol === 'https:'
    } catch {
      return false
    }
  }
}
