import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["main", "thumb"]

  select(event) {
    const selected = event.currentTarget
    this.mainTarget.src = selected.dataset.gallerySrc
    this.mainTarget.alt = selected.dataset.galleryAlt

    this.thumbTargets.forEach((button) => {
      button.setAttribute("aria-pressed", String(button === selected))
    })
  }
}
