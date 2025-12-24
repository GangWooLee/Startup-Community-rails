import { Controller } from "@hotwired/stimulus"

// 상대 시간 표시 컨트롤러
// data-relative-time-timestamp-value에 ISO 형식 타임스탬프를 전달하면
// 자동으로 "방금", "1분 전", "5분 전" 등으로 표시하고 주기적으로 업데이트
export default class extends Controller {
  static values = {
    timestamp: String  // ISO 8601 형식 타임스탬프
  }

  connect() {
    this.updateTime()
    this.startAutoUpdate()
  }

  disconnect() {
    this.stopAutoUpdate()
  }

  timestampValueChanged() {
    // 타임스탬프가 변경되면 즉시 업데이트
    this.updateTime()
  }

  updateTime() {
    if (!this.hasTimestampValue || !this.timestampValue) {
      this.element.textContent = ""
      return
    }

    const timestamp = new Date(this.timestampValue)
    const now = new Date()
    const diffMs = now - timestamp
    const diffSeconds = Math.floor(diffMs / 1000)
    const diffMinutes = Math.floor(diffSeconds / 60)
    const diffHours = Math.floor(diffMinutes / 60)
    const diffDays = Math.floor(diffHours / 24)

    let text = ""

    if (diffSeconds < 10) {
      text = "방금"
    } else if (diffSeconds < 60) {
      text = `${diffSeconds}초 전`
    } else if (diffMinutes < 60) {
      text = `${diffMinutes}분 전`
    } else if (diffHours < 24) {
      text = `${diffHours}시간 전`
    } else if (diffDays < 7) {
      text = `${diffDays}일 전`
    } else if (diffDays < 30) {
      const weeks = Math.floor(diffDays / 7)
      text = `${weeks}주 전`
    } else if (diffDays < 365) {
      const months = Math.floor(diffDays / 30)
      text = `${months}개월 전`
    } else {
      const years = Math.floor(diffDays / 365)
      text = `${years}년 전`
    }

    this.element.textContent = text
  }

  startAutoUpdate() {
    // 업데이트 주기 결정
    // - 1분 미만: 10초마다
    // - 1시간 미만: 1분마다
    // - 그 이상: 5분마다
    this.scheduleNextUpdate()
  }

  stopAutoUpdate() {
    if (this.updateTimer) {
      clearTimeout(this.updateTimer)
      this.updateTimer = null
    }
  }

  scheduleNextUpdate() {
    this.stopAutoUpdate()

    if (!this.hasTimestampValue || !this.timestampValue) {
      return
    }

    const timestamp = new Date(this.timestampValue)
    const now = new Date()
    const diffMs = now - timestamp
    const diffMinutes = Math.floor(diffMs / 1000 / 60)

    let interval
    if (diffMinutes < 1) {
      interval = 10000  // 10초
    } else if (diffMinutes < 60) {
      interval = 60000  // 1분
    } else {
      interval = 300000  // 5분
    }

    this.updateTimer = setTimeout(() => {
      this.updateTime()
      this.scheduleNextUpdate()
    }, interval)
  }
}
