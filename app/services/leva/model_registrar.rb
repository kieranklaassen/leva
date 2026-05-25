# frozen_string_literal: true

module Leva
  # Registers a successfully fine-tuned model into RubyLLM's in-memory registry so
  # it becomes selectable everywhere Leva lists models
  # (+RubyLLM.models.chat_models+) and runnable by any caller through the Together
  # provider (see {Leva::Providers::Together}).
  #
  # Persistence is a thin Leva-owned overlay file
  # (+Leva.config.fine_tuned_models_path+) that re-hydrates +RubyLLM.models.all+ at
  # boot (see {Leva::Engine}) and whenever the model dropdown is refreshed (see
  # {Leva::PromptOptimizer.available_models}). Leva never rewrites RubyLLM's
  # bundled catalog, so there is nothing to clobber, freeze on gem upgrade, or fail
  # to write into a read-only gem directory.
  #
  # @example Register the model from a completed run
  #   Leva::ModelRegistrar.call(fine_tune_run)
  class ModelRegistrar
    # Cache key the dropdown reads (see {Leva::PromptOptimizer.available_models}).
    AVAILABLE_MODELS_CACHE_KEY = "leva/available_models"

    # Provider slug fine-tuned models are registered under.
    PROVIDER = "together"

    # Family assigned to registered fine-tunes.
    FAMILY = "qwen3-finetune"

    # Context window assumed for a registered fine-tuned chat model.
    DEFAULT_CONTEXT_WINDOW = 32_768

    class << self
      # Registers the fine-tuned model produced by a completed fine-tune run.
      #
      # @param fine_tune_run [Leva::FineTuneRun] a completed run carrying a fine_tuned_model_id
      # @return [Boolean] true if newly registered, false if already present (idempotent)
      def call(fine_tune_run)
        register(model_info_data(fine_tune_run))
      end

      # Registers a single model (built from a Model::Info data hash) into RubyLLM's
      # in-memory registry and the overlay file. Idempotent by model id.
      #
      # @param data [Hash] Model::Info attributes; must include +:id+
      # @return [Boolean] true if newly registered in memory or overlay, false otherwise
      def register(data)
        id = data[:id]
        raise ArgumentError, "model id is required to register a fine-tuned model" if id.nil? || id.to_s.strip.empty?

        added_to_memory = add_to_registry(data)
        added_to_overlay = add_to_overlay(data)
        bust_cache if added_to_memory || added_to_overlay
        added_to_memory || added_to_overlay
      end

      # Re-hydrates RubyLLM's in-memory registry from the overlay file. Idempotent —
      # appends only models not already present. Called at boot and before reading
      # the model dropdown so models registered in another process become visible.
      #
      # @return [void]
      def sync!
        read_overlay.each { |data| add_to_registry(data) }
        nil
      end

      # @return [String] the overlay file path
      def overlay_path
        Leva.config.fine_tuned_models_path
      end

      private

      # @return [Boolean] true if appended to the in-memory registry, false if present
      def add_to_registry(data)
        return false if RubyLLM.models.all.any? { |m| m.id == data[:id] }

        RubyLLM.models.all << RubyLLM::Model::Info.new(data)
        true
      end

      # @return [Boolean] true if written to the overlay, false if already present
      def add_to_overlay(data)
        entries = read_overlay
        return false if entries.any? { |entry| entry[:id] == data[:id] }

        write_overlay(entries + [ data ])
        true
      end

      # @return [Array<Hash>] overlay entries (symbol-keyed); empty if absent/invalid
      def read_overlay
        path = overlay_path
        return [] unless path && File.exist?(path)

        JSON.parse(File.read(path), symbolize_names: true)
      rescue JSON::ParserError
        []
      end

      # @param entries [Array<Hash>]
      # @return [void]
      def write_overlay(entries)
        path = overlay_path
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, JSON.pretty_generate(entries))
      end

      # @return [void]
      def bust_cache
        return unless defined?(Rails) && Rails.respond_to?(:cache)

        Rails.cache.delete(AVAILABLE_MODELS_CACHE_KEY)
      end

      # Builds the Model::Info attributes for a run's fine-tuned model.
      # Uses +modalities+ (not a +:type+ key, which Model::Info ignores) so the
      # entry deterministically computes as a chat model.
      #
      # @param run [Leva::FineTuneRun]
      # @return [Hash]
      def model_info_data(run)
        {
          id: run.fine_tuned_model_id,
          name: registered_name(run),
          provider: PROVIDER,
          family: FAMILY,
          context_window: DEFAULT_CONTEXT_WINDOW,
          modalities: { input: [ "text" ], output: [ "text" ] },
          metadata: {
            leva_fine_tune_run_id: run.id,
            base_model: run.base_model,
            serving_base_url: run.serving_base_url
          }.compact
        }
      end

      # @param run [Leva::FineTuneRun]
      # @return [String] a human-readable display name
      def registered_name(run)
        dataset_name = run.respond_to?(:dataset) && run.dataset ? run.dataset.name : "dataset"
        "#{dataset_name} fine-tune ##{run.id}"
      end
    end
  end
end
