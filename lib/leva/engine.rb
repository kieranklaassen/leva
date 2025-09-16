module Leva
  class Engine < ::Rails::Engine
    isolate_namespace Leva

    # Configure importmap
    initializer "leva.importmap", before: "importmap" do |app|
      Leva.importmap.draw root.join("config/importmap.rb")
      Leva.importmap.cache_sweeper watches: root.join("app/javascript")
      
      ActiveSupport.on_load(:action_controller_base) do
        before_action { Leva.importmap.cache_sweeper.execute_if_updated }
      end
    end

    # Configure assets
    initializer "leva.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.precompile += %w[leva_manifest]
        app.config.assets.paths << root.join("app/javascript")
        app.config.assets.paths << root.join("app/assets/builds")
      end
    end

    # Configure Tailwind auto-build integration
    initializer "leva.tailwindcss" do |app|
      if defined?(Tailwindcss)
        app.config.tailwindcss ||= ActiveSupport::OrderedOptions.new
        app.config.tailwindcss.builds ||= {}
        app.config.tailwindcss.builds[:leva] = "#{root}/app/assets/stylesheets/leva/application.tailwind.css"
      end
    end

    # Build CSS once when engine loads in development
    initializer "leva.build_css_on_load", after: :load_config_initializers do |app|
      if Rails.env.development?
        begin
          Rails.logger.info "Building Leva CSS..."
          # Ensure rake tasks are loaded before invoking
          Rails.application.load_tasks
          Rake::Task["leva:build_css"].invoke
        rescue => e
          Rails.logger.warn "Failed to build Leva CSS on load: #{e.message}"
        end
      end
    end

  end
end
