/**
 * BridgeNative - 웹과 네이티브 앱 간 양방향 통신을 위한 싱글톤 객체
 *
 * iOS (Swift): window.webkit.messageHandlers 사용
 * Android (Kotlin): window.Android 인터페이스 사용
 *
 * 사용 예시:
 *   import BridgeNative from "bridge/native_messenger"
 *
 *   // 네이티브 앱 여부 확인
 *   if (BridgeNative.isNativeApp()) {
 *     BridgeNative.sendMessage("showAlert", { title: "알림", message: "안녕하세요" })
 *   }
 *
 *   // 콜백 등록 (네이티브에서 호출)
 *   BridgeNative.registerCallback("onPushReceived", (data) => {
 *     console.log("Push received:", data)
 *   })
 */
const BridgeNative = {
  /**
   * 등록된 콜백 함수들을 저장하는 객체
   * @type {Object.<string, Function>}
   */
  callbacks: {},

  /**
   * 현재 앱이 Hotwire Native 앱인지 확인
   * User-Agent에 "Turbo Native" 문자열 포함 여부로 판단
   * @returns {boolean}
   */
  isNativeApp() {
    return navigator.userAgent.includes("Turbo Native")
  },

  /**
   * 현재 앱이 iOS인지 확인
   * @returns {boolean}
   */
  isIOS() {
    return this.isNativeApp() && /iPhone|iPad|iPod/.test(navigator.userAgent)
  },

  /**
   * 현재 앱이 Android인지 확인
   * @returns {boolean}
   */
  isAndroid() {
    return this.isNativeApp() && /Android/.test(navigator.userAgent)
  },

  /**
   * 네이티브 앱으로 메시지 전송
   * iOS/Android 플랫폼에 맞는 브리지 사용
   *
   * @param {string} type - 메시지 타입 (예: "showAlert", "hapticFeedback")
   * @param {Object} data - 메시지 데이터
   * @returns {boolean} 전송 성공 여부
   *
   * @example
   *   BridgeNative.sendMessage("showAlert", { title: "제목", message: "내용" })
   *   BridgeNative.sendMessage("hapticFeedback", { style: "medium" })
   *   BridgeNative.sendMessage("shareContent", { url: "https://...", title: "공유" })
   */
  sendMessage(type, data = {}) {
    if (!this.isNativeApp()) {
      console.warn("[BridgeNative] Not running in native app")
      return false
    }

    const message = { type, ...data }

    try {
      // iOS WebKit MessageHandler
      if (window.webkit?.messageHandlers?.nativeApp) {
        window.webkit.messageHandlers.nativeApp.postMessage(message)
        return true
      }

      // Android JavaScript Interface
      if (window.Android?.postMessage) {
        window.Android.postMessage(JSON.stringify(message))
        return true
      }

      // Turbo Native Bridge (fallback)
      if (window.Turbo?.navigator?.adapter?.postMessage) {
        window.Turbo.navigator.adapter.postMessage(message)
        return true
      }

      console.warn("[BridgeNative] No native bridge available")
      return false
    } catch (error) {
      console.error("[BridgeNative] Error sending message:", error)
      return false
    }
  },

  /**
   * 네이티브에서 호출할 콜백 함수 등록
   * 네이티브 앱에서 window.BridgeNative.executeCallback(id, data) 호출
   *
   * @param {string} callbackId - 콜백 식별자
   * @param {Function} callback - 콜백 함수
   *
   * @example
   *   BridgeNative.registerCallback("onPushTapped", (data) => {
   *     window.location.href = data.url
   *   })
   */
  registerCallback(callbackId, callback) {
    if (typeof callback !== "function") {
      console.error("[BridgeNative] Callback must be a function")
      return
    }
    this.callbacks[callbackId] = callback
  },

  /**
   * 등록된 콜백 제거
   * @param {string} callbackId - 제거할 콜백 식별자
   */
  unregisterCallback(callbackId) {
    delete this.callbacks[callbackId]
  },

  /**
   * 네이티브에서 콜백 실행 (네이티브 앱에서 호출)
   * @param {string} callbackId - 실행할 콜백 식별자
   * @param {Object} data - 콜백에 전달할 데이터
   * @returns {*} 콜백 반환값
   */
  executeCallback(callbackId, data = {}) {
    const callback = this.callbacks[callbackId]
    if (callback) {
      try {
        return callback(data)
      } catch (error) {
        console.error(`[BridgeNative] Callback "${callbackId}" error:`, error)
      }
    } else {
      console.warn(`[BridgeNative] Callback "${callbackId}" not found`)
    }
  },

  /**
   * 햅틱 피드백 요청 (iOS/Android)
   * @param {string} style - 피드백 스타일 ("light", "medium", "heavy", "success", "warning", "error")
   */
  hapticFeedback(style = "medium") {
    this.sendMessage("hapticFeedback", { style })
  },

  /**
   * 네이티브 공유 시트 표시
   * @param {Object} options - 공유 옵션
   * @param {string} options.url - 공유할 URL
   * @param {string} options.title - 공유 제목
   * @param {string} [options.text] - 공유 텍스트
   */
  share(options) {
    this.sendMessage("share", options)
  },

  /**
   * 네이티브 알림 표시
   * @param {Object} options - 알림 옵션
   * @param {string} options.title - 알림 제목
   * @param {string} options.message - 알림 메시지
   * @param {string} [options.confirmText] - 확인 버튼 텍스트
   * @param {string} [options.cancelText] - 취소 버튼 텍스트 (있으면 취소 버튼 표시)
   */
  showAlert(options) {
    this.sendMessage("showAlert", options)
  }
}

// 전역 객체로 등록 (네이티브에서 접근용)
if (typeof window !== "undefined") {
  window.BridgeNative = BridgeNative
}

export default BridgeNative
