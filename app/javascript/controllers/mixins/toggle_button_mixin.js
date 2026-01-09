/**
 * ToggleButtonMixin - 좋아요/북마크/댓글좋아요 버튼의 공통 로직
 *
 * 사용법:
 * import { applyToggleButtonMixin } from "./mixins/toggle_button_mixin"
 *
 * class LikeButtonController extends Controller {
 *   static targets = ["icon", "count"]
 *   static values = { liked: Boolean, url: String }
 * }
 * applyToggleButtonMixin(LikeButtonController)
 */

/**
 * CSRF 토큰 가져오기
 */
export function getCsrfToken() {
  const meta = document.querySelector('meta[name="csrf-token"]')
  return meta ? meta.content : ""
}

/**
 * 401 에러 시 로그인 페이지로 리다이렉트
 */
export function handleUnauthorized(response) {
  if (response.status === 401) {
    window.location.href = "/login"
    return true
  }
  return false
}

/**
 * 토글 요청 수행
 * @param {string} url - 요청 URL
 * @param {Function} onSuccess - 성공 시 콜백 (response 전달)
 * @param {Function} onError - 실패 시 콜백 (error 전달)
 */
export async function performToggle(url, onSuccess, onError) {
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "X-CSRF-Token": getCsrfToken(),
        "Accept": "application/json",
        "Content-Type": "application/json"
      },
      credentials: "same-origin"
    })

    if (handleUnauthorized(response)) return

    if (response.ok) {
      const data = await response.json()
      if (onSuccess) onSuccess(data)
    } else {
      console.error("Toggle request failed:", response.status)
      if (onError) onError(new Error(`HTTP ${response.status}`))
    }
  } catch (error) {
    console.error("Toggle request error:", error)
    if (onError) onError(error)
  }
}

/**
 * 아이콘 애니메이션 (scale-125 bounce)
 * @param {HTMLElement} element - 애니메이션 대상 요소
 * @param {number} duration - 애니메이션 지속 시간 (ms)
 */
export function animateIcon(element, duration = 200) {
  if (!element) return

  element.classList.add("scale-125")
  setTimeout(() => {
    element.classList.remove("scale-125")
  }, duration)
}

/**
 * SVG 아이콘 fill 토글
 * @param {SVGElement} svg - SVG 요소
 * @param {boolean} isActive - 활성 상태
 * @param {string} activeColor - 활성 색상 클래스 (예: "text-red-500")
 * @param {string} inactiveColor - 비활성 색상 클래스 (예: "text-gray-400")
 */
export function toggleIconFill(svg, isActive, activeColor, inactiveColor) {
  if (!svg) return

  if (isActive) {
    svg.classList.remove(inactiveColor)
    svg.classList.add(activeColor)
    svg.setAttribute("fill", "currentColor")
  } else {
    svg.classList.remove(activeColor)
    svg.classList.add(inactiveColor)
    svg.setAttribute("fill", "none")
  }
}

/**
 * 카운트 업데이트
 * @param {HTMLElement} countElement - 카운트 표시 요소
 * @param {number} count - 새 카운트 값
 */
export function updateCount(countElement, count) {
  if (!countElement) return

  countElement.textContent = count
  // 0이면 숨기고, 0보다 크면 표시
  countElement.classList.toggle("hidden", count === 0)
}

/**
 * Mixin 적용 함수 (선택적 사용)
 * 컨트롤러에 공통 메서드를 주입합니다.
 */
export function applyToggleButtonMixin(ControllerClass) {
  const proto = ControllerClass.prototype

  proto.getCsrfToken = getCsrfToken
  proto.handleUnauthorized = handleUnauthorized
  proto.performToggle = function(url, onSuccess, onError) {
    return performToggle(url, onSuccess, onError)
  }
  proto.animateIcon = function(element, duration) {
    return animateIcon(element, duration)
  }
  proto.toggleIconFill = function(svg, isActive, activeColor, inactiveColor) {
    return toggleIconFill(svg, isActive, activeColor, inactiveColor)
  }
  proto.updateCount = function(countElement, count) {
    return updateCount(countElement, count)
  }

  return ControllerClass
}
