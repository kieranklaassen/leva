module Leva
  class Engine < ::Rails::Engine
    isolate_namespace Leva

    # Importmap support (kept for backward compatibility when host opts into importmap)
    # If using jsbundling-rails, the layout will include the bundled JS instead.
    initializer "leva.importmap", before: "importmap" do |app|
      if defined?(Importmap)
        Leva.importmap.draw root.join("config/importmap.rb")
        Leva.importmap.cache_sweeper watches: root.join("app/javascript")

        ActiveSupport.on_load(:action_controller_base) do
          before_action { Leva.importmap.cache_sweeper.execute_if_updated }
        end
      end
    end

    # Configure assets
    initializer "leva.assets" do |app|
      if app.config.respond_to?(:assets)
        # Make sure all relevant asset directories are on the load path for both Propshaft and Sprockets
        app.config.assets.paths << root.join("app", "javascript")
        app.config.assets.paths << root.join("app", "assets", "builds")
        app.config.assets.paths << root.join("app", "assets", "images")
        app.config.assets.paths << root.join("app", "assets", "svgs")

        # For Sprockets, explicitly precompile the engine manifest so CSS/JS/images are available
        if defined?(::Sprockets)
          app.config.assets.precompile += %w[
            leva_manifest.js
            leva/application.tailwind.css
            leva/application.js
          ]
        end
      end
    end

    # Build assets once when engine loads in development (best-effort, no-op if toolchain missing)
    initializer "leva.build_assets_on_load", after: :load_config_initializers do |app|
      if Rails.env.development?
        begin
          Rails.logger.info "Building Leva assets..."
          # Ensure rake tasks are loaded before invoking
          Rails.application.load_tasks
          Rake::Task["leva:build_css"].invoke if Rake::Task.task_defined?("leva:build_css")
          Rake::Task["leva:build_js"].invoke if Rake::Task.task_defined?("leva:build_js")
        rescue => e
          Rails.logger.warn "Failed to build Leva assets on load: #{e.message}"
        end
      end
    end

  end
end
