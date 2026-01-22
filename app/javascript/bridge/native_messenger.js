/**
 * Native Messenger - Hotwire Native 앱 통신 모듈
 *
 * WebView와 네이티브 앱(iOS/Android) 간 양방향 통신을 담당합니다.
 * 싱글톤 패턴으로 전역 네임스페이스 오염을 방지합니다.
 *
 * @example 메시지 전송
 *   import BridgeNative from 'bridge/native_messenger'
 *   BridgeNative.sendMessage('showAlert', { title: '알림', message: '저장되었습니다.' })
 *
 * @example 콜백 등록
 *   BridgeNative.registerCallback('onPhotoSelected', (data) => {
 *     console.log('선택된 사진:', data.imageUrl)
 *   })
 */

const BridgeNative = {
  // 콜백 저장소
  callbacks: {},

  // 메시지 ID 카운터 (콜백 추적용)
  messageId: 0,

  /**
   * Hotwire Native 앱 환경인지 확인
   * @returns {boolean}
   */
  isNativeApp() {
    return navigator.userAgent.includes('Turbo Native')
  },

  /**
   * iOS 앱인지 확인
   * @returns {boolean}
   */
  isIOS() {
    return this.isNativeApp() && /iPhone|iPad|iPod/.test(navigator.userAgent)
  },

  /**
   * Android 앱인지 확인
   * @returns {boolean}
   */
  isAndroid() {
    return this.isNativeApp() && /Android/.test(navigator.userAgent)
  },

  /**
   * 네이티브 앱에 메시지 전송
   *
   * @param {string} type - 메시지 타입 (예: 'showAlert', 'requestPhoto')
   * @param {Object} data - 전송할 데이터
   * @param {Function} callback - 응답 콜백 (선택)
   * @returns {string|null} 메시지 ID (콜백이 있을 경우)
   */
  sendMessage(type, data = {}, callback = null) {
    if (!this.isNativeApp()) {
      console.warn('[BridgeNative] Not in native app environment')
      return null
    }

    const id = callback ? this._generateId() : null

    if (callback) {
      this.callbacks[id] = callback
    }

    const message = {
      type,
      data,
      callbackId: id
    }

    this._postMessage(message)

    return id
  },

  /**
   * 네이티브에서 호출할 콜백 등록
   *
   * @param {string} name - 콜백 이름
   * @param {Function} fn - 콜백 함수
   */
  registerCallback(name, fn) {
    this.callbacks[name] = fn
  },

  /**
   * 등록된 콜백 제거
   *
   * @param {string} name - 콜백 이름
   */
  unregisterCallback(name) {
    delete this.callbacks[name]
  },

  /**
   * 네이티브에서 콜백 실행 (네이티브 앱에서 호출)
   *
   * @param {string} callbackId - 콜백 ID 또는 이름
   * @param {Object} data - 응답 데이터
   */
  executeCallback(callbackId, data) {
    const callback = this.callbacks[callbackId]

    if (callback) {
      callback(data)

      // 일회성 콜백이면 삭제 (숫자 ID는 일회성)
      if (typeof callbackId === 'number' || /^\d+$/.test(callbackId)) {
        delete this.callbacks[callbackId]
      }
    } else {
      console.warn(`[BridgeNative] Callback not found: ${callbackId}`)
    }
  },

  // ========== Private Methods ==========

  /**
   * 고유 메시지 ID 생성
   * @private
   */
  _generateId() {
    return `msg_${++this.messageId}_${Date.now()}`
  },

  /**
   * 플랫폼별 메시지 전송
   * @private
   */
  _postMessage(message) {
    const json = JSON.stringify(message)

    if (this.isIOS()) {
      // iOS: WKWebView postMessage
      window.webkit?.messageHandlers?.nativeApp?.postMessage(message)
    } else if (this.isAndroid()) {
      // Android: JavascriptInterface
      window.NativeApp?.postMessage(json)
    }

    // 디버그 로깅 (개발 환경에서만)
    if (process?.env?.NODE_ENV === 'development') {
      console.log('[BridgeNative] Message sent:', message)
    }
  }
}

// 네이티브 앱에서 콜백을 호출할 수 있도록 전역 등록
if (typeof window !== 'undefined') {
  window.BridgeNative = BridgeNative
}

export default BridgeNative
