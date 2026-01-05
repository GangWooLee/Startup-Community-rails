import { Controller } from "@hotwired/stimulus"

// Toggle Form Controller
// Automatically submits form when checkbox/toggle is changed
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
