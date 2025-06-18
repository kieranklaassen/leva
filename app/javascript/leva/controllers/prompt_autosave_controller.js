import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "status"]
  static values = { url: String }

  connect() {
    this.debouncedSave = this.debounce(this.save.bind(this), 1000)
    this.adjustTextareaHeight()
    this.inputTargets.forEach(input => {
      input.addEventListener('input', () => this.adjustTextareaHeight(input))
    })
  }

  adjustTextareaHeight(textarea = null) {
    const textareas = textarea ? [textarea] : this.inputTargets
    textareas.forEach(ta => {
      ta.style.height = 'auto'
      ta.style.height = (ta.scrollHeight + 5) + 'px'
      
      // Ensure horizontal text wrapping
      ta.style.wordBreak = 'break-word'
      ta.style.wordWrap = 'break-word'
    })
  }

  debouncedSave() {
    this.debouncedSave()
  }

  save() {
    const data = new FormData()
    this.inputTargets.forEach(input => {
      data.append(input.name, input.value)
    })

    this.statusTarget.textContent = "Saving..."
    this.statusTarget.classList.add("text-yellow-500")

    fetch(this.urlValue, {
      method: 'PATCH',
      body: data,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      },
      credentials: 'same-origin'
    })
    .then(response => response.json())
    .then(data => {
      if (data.status === 'success') {
        this.statusTarget.textContent = "Changes saved successfully"
        this.statusTarget.classList.remove("text-yellow-500")
        this.statusTarget.classList.add("text-green-500")
      } else {
        this.statusTarget.textContent = `Error: ${data.errors.join(", ")}`
        this.statusTarget.classList.remove("text-yellow-500")
        this.statusTarget.classList.add("text-red-500")
      }
      setTimeout(() => {
        this.statusTarget.textContent = ""
        this.statusTarget.classList.remove("text-green-500", "text-red-500")
      }, 3000)
    })
    .catch(error => {
      console.error('Error:', error)
      this.statusTarget.textContent = "Error saving changes"
      this.statusTarget.classList.remove("text-yellow-500")
      this.statusTarget.classList.add("text-red-500")
    })
  }

  debounce(func, wait) {
    let timeout
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout)
        func(...args)
      }
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
    }
  }
}