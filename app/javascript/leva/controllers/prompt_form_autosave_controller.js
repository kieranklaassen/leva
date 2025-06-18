import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]

  connect() {
    this.timeout = null
    this.debounceTime = 1000 // 1 second debounce
    this.lastSavedContent = this.formContent()
  }

  autoSave() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const currentContent = this.formContent()
      if (currentContent !== this.lastSavedContent) {
        this.submitForm()
      } else {
        this.showStatus("No changes to save", "text-gray-500")
      }
    }, this.debounceTime)
  }

  submitForm() {
    const form = this.element
    const formData = new FormData(form)

    this.showStatus("Saving...", "text-yellow-500")

    fetch(form.action, {
      method: form.method,
      body: formData,
      headers: {
        "Accept": "application/json",
        "X-Requested-With": "XMLHttpRequest",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
    })
    .then(response => response.json())
    .then(data => {
      if (data.status === "success") {
        this.showStatus("Changes saved successfully", "text-green-500")
        this.lastSavedContent = this.formContent()
      } else {
        this.showStatus(`Error: ${data.errors.join(", ")}`, "text-red-500")
      }
    })
    .catch(error => {
      console.error("Error:", error)
      this.showStatus("Error saving changes", "text-red-500")
    })
  }

  showStatus(message, className) {
    this.statusTarget.textContent = message
    this.statusTarget.className = `mb-4 text-center ${className}`
    setTimeout(() => {
      this.statusTarget.textContent = ""
      this.statusTarget.className = "mb-4 text-center"
    }, 3000)
  }

  formContent() {
    return JSON.stringify(Object.fromEntries(new FormData(this.element)))
  }
}