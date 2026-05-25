# frozen_string_literal: true

module Leva
  # Runs a dataset fine-tune asynchronously: starts the run, delegates to the
  # provider adapter (U1), records progress, and on success registers the
  # resulting model in RubyLLM (U3). Mirrors {Leva::PromptOptimizationJob}.
  #
  # @example
  #   run = FineTuneRun.create!(dataset: dataset, base_model: FineTuneRun::DEFAULT_BASE_MODEL)
  #   Leva::FineTuneJob.perform_later(fine_tune_run_id: run.id)
  class FineTuneJob < ApplicationJob
    queue_as :default

    # Maps a run's provider to its adapter class (string-named to avoid load-order coupling).
    ADAPTERS = { "together" => "Leva::FineTuners::Together" }.freeze

    # @param fine_tune_run_id [Integer]
    # @return [void]
    def perform(fine_tune_run_id:)
      @run = FineTuneRun.find(fine_tune_run_id)
      @run.start!

      result = adapter_for(@run.provider).run(@run)

      @run.complete!(result: result)
      register_model
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "[Leva::FineTuneJob] FineTuneRun not found: #{e.message}"
      raise
    rescue Leva::FineTuneError => e
      @run&.fail!(e.message)
      Rails.logger.error "[Leva::FineTuneJob] Fine-tune failed: #{e.message}"
      raise
    rescue StandardError => e
      Rails.logger.error "[Leva::FineTuneJob] Unexpected error: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      @run&.fail!(e.message.to_s.truncate(500))
      raise
    end

    private

    # Registers the fine-tuned model after a successful run. Training already
    # succeeded and the run is completed, so a registration failure is logged
    # rather than flipping the run to failed (which would hide a usable result).
    # @return [void]
    def register_model
      ModelRegistrar.call(@run)
    rescue StandardError => e
      Rails.logger.error "[Leva::FineTuneJob] Training succeeded but model registration failed: #{e.message}"
    end

    # @param provider [String]
    # @return [Leva::FineTuners::Base]
    # @raise [Leva::FineTuneError] for an unknown provider
    def adapter_for(provider)
      class_name = ADAPTERS[provider.to_s]
      raise Leva::FineTuneError, "Unknown fine-tune provider: #{provider}" unless class_name

      class_name.constantize.new(progress: method(:update_progress))
    end

    # @return [void]
    def update_progress(step:, progress:)
      @run.update_progress(step: step, progress: progress)
    end
  end
end
