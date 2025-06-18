// stimulus-loading.js
export function eagerLoadControllersFrom(path, application) {
  const controllers = import.meta.glob(path)
  for (const [filename, importController] of Object.entries(controllers)) {
    importController().then(module => {
      const identifier = identifierForFilename(filename)
      if (identifier) {
        application.register(identifier, module.default)
      }
    })
  }
}

function identifierForFilename(filename) {
  const parts = filename.split("/")
  const file = parts[parts.length - 1]
  if (file.endsWith("_controller.js")) {
    return file.slice(0, -14).replace(/_/g, "-")
  }
}
EOF < /dev/null