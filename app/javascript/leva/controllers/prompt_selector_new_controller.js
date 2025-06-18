import { Controller } from "@hotwired/stimulus"
import { marked } from "marked"

export default class extends Controller {
  static targets = ["userPromptField", "promptPreview", "previewContent"]

  toggleUserPrompt(event) {
    const selectedContent = event.target.value
    if (selectedContent) {
      this.userPromptFieldTarget.style.display = 'none'
      this.promptPreviewTarget.classList.remove('hidden')
      this.loadPredefinedPrompt(selectedContent)
    } else {
      this.userPromptFieldTarget.style.display = 'block'
      this.promptPreviewTarget.classList.add('hidden')
      this.clearUserPrompt()
    }
  }

  loadPredefinedPrompt(content) {
    const userPromptTextarea = this.userPromptFieldTarget.querySelector('textarea')
    userPromptTextarea.value = content
    this.previewContentTarget.innerHTML = marked.parse(content)
    
    // Trigger preview overflow check
    this.checkPreviewOverflow()
  }

  clearUserPrompt() {
    const userPromptTextarea = this.userPromptFieldTarget.querySelector('textarea')
    userPromptTextarea.value = ''
    this.previewContentTarget.innerHTML = ''
  }

  checkPreviewOverflow() {
    const preview = this.previewContentTarget
    const showBtn = document.getElementById('show-full-preview')
    
    if (preview.scrollHeight > preview.clientHeight || preview.scrollWidth > preview.clientWidth) {
      preview.style.maxHeight = '12em'
      preview.style.overflow = 'auto'
      showBtn?.classList.remove('hidden')
    }
  }
}