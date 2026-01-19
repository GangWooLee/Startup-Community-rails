// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "trix"
import "@rails/actiontext"

// =============================================================================
// Global Error Handler: "disconnected port object" 오류 억제
// =============================================================================
// 이 오류는 다음 상황에서 발생할 수 있음:
// 1. Turbo 내부 MessageChannel이 페이지 네비게이션 중 해제됨
// 2. 브라우저 확장 프로그램 (비밀번호 관리자, 광고 차단기)의 port 통신
// 3. ActionCable WebSocket 연결 상태 변경
// 기능에 영향 없으며, 콘솔 오류만 발생하므로 억제
window.addEventListener("error", (event) => {
  if (event.message?.includes("disconnected port object")) {
    event.preventDefault()
    console.debug("[App] Suppressed disconnected port error (no impact on functionality)")
    return true
  }
})

window.addEventListener("unhandledrejection", (event) => {
  if (event.reason?.message?.includes("disconnected port object")) {
    event.preventDefault()
    console.debug("[App] Suppressed disconnected port rejection (no impact on functionality)")
  }
})
