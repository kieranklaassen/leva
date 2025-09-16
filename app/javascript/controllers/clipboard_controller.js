import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  copy(event) {
    const sourceId = event.currentTarget.dataset.clipboardSource
    const sourceElement = document.getElementById(sourceId)
    const content = sourceElement.value || sourceElement.textContent
    navigator.clipboard.writeText(content).then(() => {
      this.showFeedback(event.currentTarget, "Copied!")
    }, (err) => {
      console.error('Could not copy text: ', err)
      this.showFeedback(event.currentTarget, "Failed to copy", true)
    })
  }

  showFeedback(button, message, isError = false) {
    const originalText = button.textContent
    button.textContent = message
    button.classList.add(isError ? "text-red-500" : "text-green-500")
    button.disabled = true

    setTimeout(() => {
      button.textContent = originalText
      button.classList.remove("text-green-500", "text-red-500")
      button.disabled = false
    }, 2000)
  }
}