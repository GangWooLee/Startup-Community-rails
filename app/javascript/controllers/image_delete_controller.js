import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    confirmMessage: { type: String, default: "이 이미지를 삭제하시겠습니까?" }
  }

  async delete(event) {
    event.preventDefault()
    event.stopPropagation()

    if (!confirm(this.confirmMessageValue)) {
      return
    }

    try {
      const response = await fetch(this.urlValue, {
        method: 'DELETE',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || ''
        }
      })

      if (response.ok) {
        const contentType = response.headers.get('Content-Type')
        if (contentType && contentType.includes('text/vnd.turbo-stream.html')) {
          // Turbo Stream 응답 처리
          const html = await response.text()
          Turbo.renderStreamMessage(html)
        } else {
          // DOM에서 직접 제거 (fallback)
          this.element.remove()
        }
      } else {
        alert('이미지 삭제에 실패했습니다.')
      }
    } catch (error) {
      console.error('Error deleting image:', error)
      alert('이미지 삭제 중 오류가 발생했습니다.')
    }
  }
}
