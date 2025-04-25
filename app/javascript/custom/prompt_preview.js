document.addEventListener('DOMContentLoaded', () => {
  const wrapper     = document.getElementById('prompt-preview');
  const preview     = document.getElementById('preview-content');
  const showBtn     = document.getElementById('show-full-preview');
  const dialog      = document.getElementById('full-preview-dialog');
  const dialogBody  = document.getElementById('dialog-content');
  const closeBtn    = document.getElementById('close-full-preview');

  if (!preview) return;

  // Check if the preview content is already populated by Stimulus
  const checkPreviewContent = () => {
    if (preview.textContent.trim().length > 0) {
      // Detect overflow
      if (preview.scrollWidth > preview.clientWidth) {
        preview.style.maxHeight = '6em';  // optional: clamp height
        preview.style.overflow = 'hidden';
        showBtn.classList.remove('hidden');
      }
    } else {
      // If not populated yet, check again after a short delay
      setTimeout(checkPreviewContent, 100);
    }
  };

  // Start checking once the wrapper is visible
  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
        if (!wrapper.classList.contains('hidden')) {
          checkPreviewContent();
          observer.disconnect(); // Stop observing once we've detected the change
        }
      }
    });
  });

  observer.observe(wrapper, { attributes: true });

  // Show full in dialog
  showBtn.addEventListener('click', () => {
    dialogBody.textContent = preview.textContent;
    dialog.showModal();
  });

  // Close dialog
  closeBtn.addEventListener('click', () => dialog.close());
});
