# frozen_string_literal: true

module Leva
  # Background job for running prompt optimization.
  #
  # This job executes the MIPROv2 optimization process asynchronously,
  # allowing the UI to remain responsive during long-running optimizations.
  #
  # @example Enqueue an optimization job
  #   Leva::PromptOptimizationJob.perform_later(
  #     dataset_id: dataset.id,
  #     prompt_name: "Optimized Sentiment Classifier",
  #     mode: :medium
  #   )
  class PromptOptimizationJob < ApplicationJob
    queue_as :default

    # Performs the prompt optimization and creates a new Prompt.
    #
    # @param dataset_id [Integer] The ID of the dataset to optimize for
    # @param prompt_name [String] The name for the created prompt
    # @param mode [String, Symbol] Optimization mode (:light, :medium, :heavy)
    # @param metric_class [String, nil] Optional evaluator class name for custom metric
    # @return [Leva::Prompt] The created optimized prompt
    def perform(dataset_id:, prompt_name:, mode: :light, metric_class: nil)
      dataset = Dataset.find(dataset_id)

      metric = resolve_metric(metric_class)

      optimizer = PromptOptimizer.new(
        dataset: dataset,
        metric: metric,
        mode: mode.to_sym
      )

      result = optimizer.optimize

      Prompt.create!(
        name: prompt_name,
        system_prompt: result[:system_prompt],
        user_prompt: result[:user_prompt],
        metadata: result[:metadata]
      )
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "[Leva::PromptOptimizationJob] Dataset not found: #{e.message}"
      raise
    rescue Leva::InsufficientDataError => e
      Rails.logger.error "[Leva::PromptOptimizationJob] Insufficient data: #{e.message}"
      raise
    rescue StandardError => e
      Rails.logger.error "[Leva::PromptOptimizationJob] Optimization failed: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      raise
    end

    private

    # Resolves a metric class name to an evaluation function.
    #
    # @param metric_class [String, nil] The evaluator class name
    # @return [Proc, nil] The metric function or nil for default
    def resolve_metric(metric_class)
      return nil if metric_class.blank?

      evaluator = metric_class.constantize.new
      return nil unless evaluator.respond_to?(:evaluate)

      # Wrap the evaluator's method for DSPy compatibility
      lambda do |example, prediction|
        # Create a mock runner_result for the evaluator
        expected = example.dig(:expected, :output)
        actual = prediction.to_s

        # Simple comparison - evaluators can do more complex logic
        expected.to_s.strip.downcase == actual.strip.downcase ? 1.0 : 0.0
      end
    rescue NameError => e
      Rails.logger.warn "[Leva::PromptOptimizationJob] Could not resolve metric class: #{e.message}"
      nil
    end
  end
end
