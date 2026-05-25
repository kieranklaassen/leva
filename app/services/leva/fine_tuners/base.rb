# frozen_string_literal: true

module Leva
  module FineTuners
    # Adapter interface for fine-tune providers.
    #
    # Concrete adapters (e.g. {Leva::FineTuners::Together}) train a model from a
    # dataset and return a *serving binding* — not a bare model id — so the
    # downstream {Leva::ModelRegistrar} stays provider-agnostic:
    #
    #   { model_id:, serving_base_url:, api_key_env:, serverless: }
    #
    # Providers that serve serverless (Together) fill +serving_base_url+ with a
    # constant; providers that deploy a per-model endpoint (a future RunPod
    # adapter) fill it with the provisioned URL.
    #
    # @abstract Subclass and override {#run}.
    class Base
      # @param progress [#call, nil] optional callback invoked as
      #   +progress.call(step:, progress:)+ during the run
      def initialize(progress: nil)
        @progress = progress
      end

      # Runs the fine-tune to completion.
      #
      # @param fine_tune_run [Leva::FineTuneRun] the run to execute
      # @return [Hash] the serving binding (see class docs)
      # @raise [NotImplementedError] if not overridden
      def run(fine_tune_run)
        raise NotImplementedError, "#{self.class} must implement #run"
      end

      protected

      # Reports progress to the callback when present.
      #
      # @param step [String]
      # @param progress [Integer]
      # @return [void]
      def report(step:, progress:)
        @progress&.call(step: step, progress: progress)
      end
    end
  end
end
