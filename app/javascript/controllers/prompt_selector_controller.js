import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["userPromptField"];

  toggleUserPrompt(event) {
    const selectedFile = event.target.value;
    if (selectedFile) {
      this.userPromptFieldTarget.style.display = "none";
      this.loadPredefinedPrompt(selectedFile);
    } else {
      this.userPromptFieldTarget.style.display = "block";
      this.clearUserPrompt();
    }
  }

  loadPredefinedPrompt(file) {
    fetch(file)
      .then((response) => response.text())
      .then((content) => {
        const userPromptTextarea = this.userPromptFieldTarget.querySelector("textarea");
        userPromptTextarea.value = content;
      })
      .catch((error) => console.error("Error loading predefined prompt:", error));
  }

  clearUserPrompt() {
    const userPromptTextarea = this.userPromptFieldTarget.querySelector("textarea");
    userPromptTextarea.value = "";
  }
}
