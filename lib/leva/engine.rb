module Leva
  class Engine < ::Rails::Engine
    isolate_namespace Leva

    initializer "leva.assets" do |app|
      # Add asset paths for both Sprockets and Propshaft
      app.config.assets.paths << root.join("app/assets/stylesheets").to_s

      # For Sprockets: explicitly precompile leva assets
      if app.config.respond_to?(:assets) && app.config.assets.respond_to?(:precompile)
        app.config.assets.precompile += %w[leva/application.css]
      end
    end
  end
end
