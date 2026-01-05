import { Controller } from "@hotwired/stimulus"

/**
 * Job Filter Controller
 *
 * Handles filtering and searching for job posts (Makers & Projects)
 *
 * Features:
 * - Filter by service type (development, design, etc.)
 * - Search by title
 * - Smooth scroll to sections
 * - Active chip state management
 */
export default class extends Controller {
  static targets = [
    "chip",           // Filter chips
    "search",         // Search input
    "card",           // Job cards
    "makersGrid",     // Makers grid container
    "projectsGrid",   // Projects grid container
    "makersSection",  // Makers section
    "projectsSection" // Projects section
  ]

  connect() {
    this.currentFilter = "all"
    this.searchQuery = ""
  }

  /**
   * Filter cards by service type
   * @param {Event} event - Click event from chip button
   */
  filterByType(event) {
    const chip = event.currentTarget
    const serviceType = chip.dataset.serviceType

    // Update active chip state
    // Drawbridge Task #102: bg-orange-500 → bg-stone-900 (더 자연스러운 톤)
    // Drawbridge Task #111, #112: border 통일 + 선택 시 흰 글씨/검은 배경
    this.chipTargets.forEach(c => {
      c.classList.remove("bg-stone-900", "text-white", "shadow-sm", "border-stone-900", "font-semibold")
      c.classList.add("bg-white", "text-stone-600", "border-stone-200", "font-medium", "hover:bg-stone-50", "hover:border-stone-300")
    })
    chip.classList.remove("bg-white", "text-stone-600", "border-stone-200", "font-medium", "hover:bg-stone-50", "hover:border-stone-300")
    chip.classList.add("bg-stone-900", "text-white", "border-stone-900", "shadow-sm", "font-semibold")

    this.currentFilter = serviceType
    this.applyFilters()
  }

  /**
   * Filter cards by search query
   * @param {Event} event - Input event from search field
   */
  filterBySearch(event) {
    this.searchQuery = event.target.value.toLowerCase().trim()
    this.applyFilters()
  }

  /**
   * Apply all active filters to cards
   */
  applyFilters() {
    const cards = this.cardTargets

    cards.forEach(card => {
      const cardServiceType = card.dataset.serviceType || ""
      const cardTitle = card.dataset.title || ""

      // Check service type filter
      const matchesType = this.currentFilter === "all" ||
                          cardServiceType === this.currentFilter

      // Check search filter
      const matchesSearch = this.searchQuery === "" ||
                            cardTitle.includes(this.searchQuery)

      // Show/hide card with animation
      if (matchesType && matchesSearch) {
        card.classList.remove("hidden", "opacity-0", "scale-95")
        card.classList.add("opacity-100", "scale-100")
      } else {
        card.classList.add("hidden", "opacity-0", "scale-95")
        card.classList.remove("opacity-100", "scale-100")
      }
    })

    // Update empty states
    this.updateEmptyStates()
  }

  /**
   * Update empty state messages when all cards are hidden
   */
  updateEmptyStates() {
    // Check makers section
    if (this.hasMakersGridTarget) {
      const visibleMakers = this.makersGridTarget.querySelectorAll(".job-card:not(.hidden)")
      const makersEmpty = this.makersSectionTarget.querySelector(".empty-filter-state")

      if (visibleMakers.length === 0 && !makersEmpty) {
        this.showEmptyFilterState(this.makersGridTarget, "Makers")
      } else if (visibleMakers.length > 0 && makersEmpty) {
        makersEmpty.remove()
      }
    }

    // Check projects section
    if (this.hasProjectsGridTarget) {
      const visibleProjects = this.projectsGridTarget.querySelectorAll(".job-card:not(.hidden)")
      const projectsEmpty = this.projectsSectionTarget.querySelector(".empty-filter-state")

      if (visibleProjects.length === 0 && !projectsEmpty) {
        this.showEmptyFilterState(this.projectsGridTarget, "Projects")
      } else if (visibleProjects.length > 0 && projectsEmpty) {
        projectsEmpty.remove()
      }
    }
  }

  /**
   * Show empty state when filter returns no results (using safe DOM methods)
   * @param {HTMLElement} container - Grid container
   * @param {string} type - "Makers" or "Projects"
   */
  showEmptyFilterState(container, type) {
    const emptyState = document.createElement("div")
    emptyState.className = "empty-filter-state col-span-full text-center py-12"

    // Create icon container
    const iconContainer = document.createElement("div")
    iconContainer.className = "w-12 h-12 mx-auto mb-3 rounded-xl bg-stone-100 flex items-center justify-center"

    // Create SVG icon using createElementNS for proper SVG creation
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.setAttribute("class", "w-6 h-6 text-stone-400")
    svg.setAttribute("fill", "none")
    svg.setAttribute("stroke", "currentColor")
    svg.setAttribute("viewBox", "0 0 24 24")

    const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
    path.setAttribute("stroke-linecap", "round")
    path.setAttribute("stroke-linejoin", "round")
    path.setAttribute("stroke-width", "2")
    path.setAttribute("d", "M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z")

    svg.appendChild(path)
    iconContainer.appendChild(svg)

    // Create text elements
    const title = document.createElement("p")
    title.className = "text-stone-600 font-medium"
    title.textContent = "검색 결과가 없습니다"

    const subtitle = document.createElement("p")
    subtitle.className = "text-sm text-stone-500"
    subtitle.textContent = "다른 조건으로 검색해보세요"

    // Assemble the empty state
    emptyState.appendChild(iconContainer)
    emptyState.appendChild(title)
    emptyState.appendChild(subtitle)

    container.appendChild(emptyState)
  }

  /**
   * Smooth scroll to Makers section
   * @param {Event} event - Click event
   */
  scrollToMakers(event) {
    event.preventDefault()
    if (this.hasMakersSectionTarget) {
      this.makersSectionTarget.scrollIntoView({
        behavior: "smooth",
        block: "start"
      })
    }
  }

  /**
   * Smooth scroll to Projects section
   * @param {Event} event - Click event
   */
  scrollToProjects(event) {
    event.preventDefault()
    if (this.hasProjectsSectionTarget) {
      this.projectsSectionTarget.scrollIntoView({
        behavior: "smooth",
        block: "start"
      })
    }
  }

  /**
   * Reset all filters
   */
  resetFilters() {
    // Reset chip state
    // Drawbridge Task #102: bg-orange-500 → bg-stone-900
    // Drawbridge Task #111, #112: border 통일 + 선택 시 흰 글씨/검은 배경
    this.chipTargets.forEach((chip, index) => {
      if (index === 0) {
        chip.classList.add("bg-stone-900", "text-white", "border-stone-900", "shadow-sm", "font-semibold")
        chip.classList.remove("bg-white", "text-stone-600", "border-stone-200", "font-medium", "hover:bg-stone-50", "hover:border-stone-300")
      } else {
        chip.classList.remove("bg-stone-900", "text-white", "border-stone-900", "shadow-sm", "font-semibold")
        chip.classList.add("bg-white", "text-stone-600", "border-stone-200", "font-medium", "hover:bg-stone-50", "hover:border-stone-300")
      }
    })

    // Reset search
    if (this.hasSearchTarget) {
      this.searchTarget.value = ""
    }

    this.currentFilter = "all"
    this.searchQuery = ""
    this.applyFilters()
  }
}
