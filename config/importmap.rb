pin "application", to: "leva/application.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from Leva::Engine.root.join("app/javascript/leva/controllers"), under: "controllers", to: "leva/controllers"

# Pin marked for markdown parsing  
pin "marked", to: "https://cdn.jsdelivr.net/npm/marked@14.1.4/+esm"
