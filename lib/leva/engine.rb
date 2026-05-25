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

    # Register the Together provider so fine-tuned models are runnable through the
    # normal RubyLLM path (see Leva::Providers::Together and Leva::ModelRegistrar).
    initializer "leva.register_together_provider" do
      Leva::Engine.register_together_provider!
    end

    # Re-hydrate RubyLLM's in-memory registry with Leva-registered fine-tuned
    # models. Runs after the app is initialized so the autoloaded service is ready.
    config.after_initialize do
      Leva::ModelRegistrar.sync!
    rescue StandardError => e
      Rails.logger.warn("[Leva] fine-tuned model sync skipped: #{e.message}") if defined?(Rails)
    end

    # Registers the Together provider with RubyLLM after verifying the registry API
    # this feature relies on is present (guards against ruby_llm version drift).
    #
    # @return [void]
    # @raise [Leva::ConfigurationError] if the bundled RubyLLM lacks the required API
    def self.register_together_provider!
      unless RubyLLM::Provider.respond_to?(:register) && RubyLLM.models.respond_to?(:save_to_json)
        raise Leva::ConfigurationError,
          "Leva fine-tuning requires a RubyLLM exposing Provider.register and Models#save_to_json " \
          "(found ruby_llm #{defined?(RubyLLM::VERSION) ? RubyLLM::VERSION : 'unknown'}). " \
          "Pin a compatible ruby_llm version."
      end

      require "leva/providers/together"
      RubyLLM::Provider.register(:together, Leva::Providers::Together)
    end
  end
end
