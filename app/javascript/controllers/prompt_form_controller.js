import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form"];

  autoSave() {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      this.submitForm();
    }, 500);
  }

  submitForm() {
    const form = this.element;
    const formData = new FormData(form);

    fetch(form.action, {
      method: form.method,
      body: formData,
      headers: {
        Accept: "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
    })
      .then((response) => response.json())
      .then((data) => {
        const statusElement = document.getElementById("form-status");
        if (data.status === "success") {
          statusElement.textContent = "Changes saved successfully";
          statusElement.classList.add("text-green-500");
          statusElement.classList.remove("text-red-500");
        } else {
          statusElement.textContent = `Error: ${data.errors.join(", ")}`;
          statusElement.classList.add("text-red-500");
          statusElement.classList.remove("text-green-500");
        }
        setTimeout(() => {
          statusElement.textContent = "";
        }, 3000);
      })
      .catch((error) => {
        console.error("Error:", error);
      });
  }
}
