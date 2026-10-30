import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "classifieds:theme"

export default class extends Controller {
  static targets = ["icon"]

  connect() {
    this.mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.handleSystemChange = () => {
      if (!this.savedPreference()) this.apply(this.mediaQuery.matches ? "dark" : "light")
    }
    this.mediaQuery.addEventListener("change", this.handleSystemChange)
    this.apply(this.savedPreference() || document.documentElement.getAttribute("data-bs-theme"))
  }

  disconnect() {
    this.mediaQuery?.removeEventListener("change", this.handleSystemChange)
  }

  toggle() {
    const next = document.documentElement.getAttribute("data-bs-theme") === "dark" ? "light" : "dark"

    try {
      window.localStorage.setItem(STORAGE_KEY, next)
    } catch (_) {
      // The toggle still works for this page when storage is unavailable.
    }
    this.apply(next)
  }

  savedPreference() {
    try {
      const value = window.localStorage.getItem(STORAGE_KEY)
      return value === "dark" || value === "light" ? value : null
    } catch (_) {
      return null
    }
  }

  apply(value) {
    const mode = value === "dark" ? "dark" : "light"
    const toDark = mode === "light"
    const label = toDark ? "Включить тёмную тему" : "Включить светлую тему"

    document.documentElement.setAttribute("data-bs-theme", mode)
    this.iconTarget.classList.toggle("bi-moon-stars", toDark)
    this.iconTarget.classList.toggle("bi-sun", !toDark)
    this.element.setAttribute("aria-label", label)
    this.element.setAttribute("title", label)
    this.element.setAttribute("aria-pressed", String(!toDark))
  }
}
