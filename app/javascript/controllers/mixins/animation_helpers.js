/**
 * AnimationHelpers - Stimulus 컨트롤러용 애니메이션 유틸리티
 *
 * 사용법:
 * import { fadeIn, fadeOut, slideInUp, delay } from "./mixins/animation_helpers"
 *
 * fadeIn(element, { duration: 300 })
 * await delay(300)
 */

/**
 * Promise 기반 지연 함수
 * @param {number} ms - 대기 시간 (밀리초)
 * @returns {Promise} 지정된 시간 후 resolve되는 Promise
 */
export function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

/**
 * 요소 페이드 인 애니메이션
 * @param {HTMLElement} element - 대상 요소
 * @param {Object} options - 애니메이션 옵션
 * @param {number} options.duration - 지속 시간 (ms), 기본 300
 * @param {string} options.easing - 이징 함수, 기본 "ease"
 * @returns {Promise} 애니메이션 완료 후 resolve
 */
export function fadeIn(element, options = {}) {
  const { duration = 300, easing = "ease" } = options

  element.style.opacity = "0"
  element.classList.remove("hidden")

  return new Promise(resolve => {
    requestAnimationFrame(() => {
      element.style.transition = `opacity ${duration}ms ${easing}`
      element.style.opacity = "1"
      setTimeout(resolve, duration)
    })
  })
}

/**
 * 요소 페이드 아웃 애니메이션
 * @param {HTMLElement} element - 대상 요소
 * @param {Object} options - 애니메이션 옵션
 * @param {number} options.duration - 지속 시간 (ms), 기본 300
 * @param {string} options.easing - 이징 함수, 기본 "ease"
 * @param {boolean} options.hide - 완료 후 hidden 클래스 추가 여부
 * @returns {Promise} 애니메이션 완료 후 resolve
 */
export function fadeOut(element, options = {}) {
  const { duration = 300, easing = "ease", hide = true } = options

  return new Promise(resolve => {
    element.style.transition = `opacity ${duration}ms ${easing}`
    element.style.opacity = "0"

    setTimeout(() => {
      if (hide) {
        element.classList.add("hidden")
      }
      resolve()
    }, duration)
  })
}

/**
 * 아래에서 위로 슬라이드 인 애니메이션
 * @param {HTMLElement} element - 대상 요소
 * @param {Object} options - 애니메이션 옵션
 * @param {number} options.duration - 지속 시간 (ms), 기본 400
 * @param {number} options.distance - 시작 거리 (px), 기본 20
 * @returns {Promise} 애니메이션 완료 후 resolve
 */
export function slideInUp(element, options = {}) {
  const { duration = 400, distance = 20, easing = "ease" } = options

  element.style.opacity = "0"
  element.style.transform = `translateY(${distance}px)`
  element.classList.remove("hidden")

  return new Promise(resolve => {
    requestAnimationFrame(() => {
      element.style.transition = `opacity ${duration}ms ${easing}, transform ${duration}ms ${easing}`
      element.style.opacity = "1"
      element.style.transform = "translateY(0)"
      setTimeout(resolve, duration)
    })
  })
}

/**
 * 위로 슬라이드 아웃 애니메이션
 * @param {HTMLElement} element - 대상 요소
 * @param {Object} options - 애니메이션 옵션
 * @returns {Promise} 애니메이션 완료 후 resolve
 */
export function slideOutUp(element, options = {}) {
  const { duration = 300, distance = 20, easing = "ease", hide = true } = options

  return new Promise(resolve => {
    element.style.transition = `opacity ${duration}ms ${easing}, transform ${duration}ms ${easing}`
    element.style.opacity = "0"
    element.style.transform = `translateY(-${distance}px)`

    setTimeout(() => {
      if (hide) {
        element.classList.add("hidden")
      }
      resolve()
    }, duration)
  })
}

/**
 * 여러 요소에 순차적 애니메이션 적용 (stagger effect)
 * @param {NodeList|Array} elements - 대상 요소들
 * @param {Function} animateFn - 각 요소에 적용할 애니메이션 함수
 * @param {Object} options - 옵션
 * @param {number} options.staggerDelay - 각 요소 사이 지연 (ms), 기본 80
 * @returns {Promise} 모든 애니메이션 완료 후 resolve
 */
export async function staggerAnimation(elements, animateFn, options = {}) {
  const { staggerDelay = 80 } = options
  const elementArray = Array.from(elements)

  for (let i = 0; i < elementArray.length; i++) {
    const element = elementArray[i]
    // 초기 상태 설정
    element.style.opacity = "0"
    element.style.transform = "translateY(16px)"

    // 지연 후 애니메이션
    setTimeout(() => {
      if (animateFn) {
        animateFn(element)
      } else {
        element.style.transition = "opacity 0.3s ease, transform 0.3s ease"
        element.style.opacity = "1"
        element.style.transform = "translateY(0)"
      }
    }, staggerDelay * i)
  }

  // 모든 애니메이션 완료 대기
  await delay(staggerDelay * elementArray.length + 300)
}

/**
 * 스케일 애니메이션 (아이콘 클릭 등에 사용)
 * @param {HTMLElement} element - 대상 요소
 * @param {Object} options - 옵션
 * @param {number} options.scale - 최대 스케일, 기본 1.25
 * @param {number} options.duration - 지속 시간 (ms), 기본 200
 */
export function scaleAnimation(element, options = {}) {
  const { scale = 1.25, duration = 200 } = options

  if (!element) return

  element.classList.add(`scale-${Math.round(scale * 100)}`)
  setTimeout(() => {
    element.classList.remove(`scale-${Math.round(scale * 100)}`)
  }, duration)
}
