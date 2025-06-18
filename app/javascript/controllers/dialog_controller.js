import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview", "dialog", "dialogContent", "showButton"]

  connect() {
    this.checkOverflow()
  }

  checkOverflow() {
    if (this.hasPreviewTarget) {
      // Use a MutationObserver to watch for content changes
      this.observer = new MutationObserver(() => {
        if (this.previewTarget.textContent.trim().length > 0) {
          if (this.previewTarget.scrollHeight > this.previewTarget.clientHeight || 
              this.previewTarget.scrollWidth > this.previewTarget.clientWidth) {
            this.previewTarget.style.maxHeight = '12em'
            this.previewTarget.style.overflow = 'auto'
            this.showButtonTarget.classList.remove('hidden')
          }
        }
      })

      this.observer.observe(this.previewTarget, { 
        childList: true, 
        characterData: true, 
        subtree: true 
      })
    }
  }

  showFull() {
    if (this.hasDialogTarget && this.hasPreviewTarget) {
      this.dialogContentTarget.innerHTML = this.previewTarget.innerHTML
      this.dialogTarget.showModal()
    }
  }

  close() {
    if (this.hasDialogTarget) {
      this.dialogTarget.close()
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
}