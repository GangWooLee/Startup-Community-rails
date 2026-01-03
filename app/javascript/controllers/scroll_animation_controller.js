import { Controller } from "@hotwired/stimulus"

/**
 * Scroll Animation Controller
 *
 * Implements Framer Motion's whileInView behavior using Intersection Observer.
 * Reference: viewport={{ once: true, margin: "-100px" }}
 *
 * Usage:
 *   <section data-controller="scroll-animation" data-scroll-animation-margin-value="-100px">
 *     <div data-scroll-animation-target="item" class="animate-on-scroll">...</div>
 *     <div data-scroll-animation-target="item" class="animate-on-scroll-card" data-animation-delay="0.1">...</div>
 *   </section>
 */
export default class extends Controller {
  static targets = ["item"]
  static values = {
    threshold: { type: Number, default: 0.2 },
    margin: { type: String, default: "-50px" }
  }

  connect() {
    this.observer = new IntersectionObserver(
      (entries) => this.handleIntersect(entries),
      {
        threshold: this.thresholdValue,
        rootMargin: this.marginValue
      }
    )

    this.itemTargets.forEach((item, index) => {
      // Apply stagger delay from data attribute or calculate from index
      const delay = item.dataset.animationDelay
      if (delay) {
        item.style.animationDelay = `${delay}s`
      } else if (item.classList.contains('animate-on-scroll-card')) {
        // Auto-calculate delay for cards (index * 0.1s as per reference)
        item.style.animationDelay = `${index * 0.1}s`
      }

      this.observer.observe(item)
    })
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  handleIntersect(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        // Add visibility class to trigger animation
        entry.target.classList.add('is-visible')

        // Unobserve after animation (once: true behavior)
        this.observer.unobserve(entry.target)
      }
    })
  }
}
