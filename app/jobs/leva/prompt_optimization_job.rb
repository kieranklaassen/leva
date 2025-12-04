# frozen_string_literal: true

module Leva
  # Background job for running prompt optimization with progress tracking.
  #
  # This job executes the optimization process asynchronously, updating
  # the OptimizationRun record with progress for live UI updates.
  #
  # @example Enqueue an optimization job
  #   run = OptimizationRun.create!(dataset: dataset, prompt_name: "My Prompt", mode: :light)
  #   Leva::PromptOptimizationJob.perform_later(optimization_run_id: run.id)
  class PromptOptimizationJob < ApplicationJob
    queue_as :default

    # Performs the prompt optimization and creates a new Prompt.
    #
    # @param optimization_run_id [Integer] The ID of the OptimizationRun to process
    # @return [Leva::Prompt] The created optimized prompt
    def perform(optimization_run_id:)
      @run = OptimizationRun.find(optimization_run_id)
      @run.start!

      dataset = @run.dataset

      optimizer = PromptOptimizer.new(
        dataset: dataset,
        mode: @run.mode.to_sym,
        model: @run.model,
        optimizer: @run.optimizer.to_sym,
        progress_callback: method(:update_progress)
      )

      result = optimizer.optimize

      prompt = Prompt.create!(
        name: @run.prompt_name,
        system_prompt: result[:system_prompt],
        user_prompt: result[:user_prompt],
        metadata: result[:metadata]
      )

      @run.complete!(prompt)
      prompt
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "[Leva::PromptOptimizationJob] OptimizationRun not found: #{e.message}"
      raise
    rescue Leva::InsufficientDataError, Leva::DspyConfigurationError, Leva::OptimizationError => e
      @run&.fail!(e)
      Rails.logger.error "[Leva::PromptOptimizationJob] Optimization failed: #{e.message}"
      raise
    rescue StandardError => e
      @run&.fail!(e)
      Rails.logger.error "[Leva::PromptOptimizationJob] Unexpected error: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      raise
    end

    private

    # Callback for progress updates from the optimizer.
    #
    # @param step [String] Current step name
    # @param progress [Integer] Progress percentage (0-100)
    # @param examples_processed [Integer, nil] Number of examples processed
    # @param total [Integer, nil] Total examples to process
    # @return [void]
    def update_progress(step:, progress:, examples_processed: nil, total: nil)
      @run.update_progress(
        step: step,
        progress: progress,
        examples_processed: examples_processed,
        total: total
      )
    end
  end
end
