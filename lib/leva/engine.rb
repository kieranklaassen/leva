module Leva
  class Engine < ::Rails::Engine
    isolate_namespace Leva

    # Configure importmap
    initializer "leva.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << root.join("app/javascript")
      end
    end

    # Configure assets
    initializer "leva.assets" do |app|
      app.config.assets.precompile += %w[
        leva/application.css
        leva/application.tailwind.css
        leva/application.js
      ]
      app.config.assets.paths << root.join("app/javascript")
      app.config.assets.paths << root.join("vendor/javascript")
    end

    # Configure Tailwind
    initializer "leva.tailwindcss" do |app|
      if defined?(Tailwindcss)
        app.config.tailwindcss ||= ActiveSupport::OrderedOptions.new
        app.config.tailwindcss.builds ||= {}
        app.config.tailwindcss.builds[:leva] = "#{root}/app/assets/stylesheets/leva/application.tailwind.css"
      end
    end
  end
end
