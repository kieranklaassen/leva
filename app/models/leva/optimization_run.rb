# frozen_string_literal: true

module Leva
  # Tracks the progress and status of prompt optimization runs.
  #
  # @example Create and track an optimization run
  #   run = OptimizationRun.create!(
  #     dataset: dataset,
  #     prompt_name: "My Optimized Prompt",
  #     mode: "light"
  #   )
  #   run.start!
  #   run.update_progress(step: "bootstrapping", progress: 50, examples_processed: 5)
  #   run.complete!(prompt)
  class OptimizationRun < ApplicationRecord
    self.table_name = "leva_optimization_runs"

    belongs_to :dataset
    belongs_to :prompt, optional: true

    enum :status, {
      pending: "pending",
      running: "running",
      completed: "completed",
      failed: "failed"
    }, default: :pending

    validates :prompt_name, presence: true, length: { maximum: 255 }
    validates :mode, presence: true, inclusion: { in: %w[light medium heavy] }
    validates :model, presence: true
    validates :optimizer, inclusion: { in: PromptOptimizer::OPTIMIZERS.keys.map(&:to_s) }
    validates :progress, numericality: { in: 0..100 }

    # Defined optimization steps for display
    STEPS = {
      "validating" => { label: "Validating dataset", icon: "check" },
      "splitting_data" => { label: "Splitting data", icon: "scissors" },
      "generating_signature" => { label: "Generating signature", icon: "code" },
      "bootstrapping" => { label: "Bootstrapping examples", icon: "zap" },
      "evaluating" => { label: "Evaluating results", icon: "bar-chart" },
      "building_result" => { label: "Building prompt", icon: "package" },
      "complete" => { label: "Complete", icon: "check-circle" }
    }.freeze

    # Marks the run as started.
    #
    # @return [void]
    def start!
      update!(status: :running, current_step: "validating", progress: 0)
    end

    # Updates the progress of the optimization run.
    #
    # @param step [String] Current step name
    # @param progress [Integer] Progress percentage (0-100)
    # @param examples_processed [Integer, nil] Number of examples processed
    # @param total [Integer, nil] Total examples to process
    # @return [void]
    def update_progress(step:, progress:, examples_processed: nil, total: nil)
      attrs = { current_step: step, progress: progress }
      attrs[:examples_processed] = examples_processed if examples_processed
      attrs[:total_examples] = total if total
      update!(attrs)
    end

    # Marks the run as completed with the created prompt.
    #
    # @param created_prompt [Leva::Prompt] The optimized prompt
    # @return [void]
    def complete!(created_prompt)
      update!(
        status: :completed,
        prompt: created_prompt,
        current_step: "complete",
        progress: 100
      )
    end

    # Marks the run as failed.
    #
    # @param error [String, Exception] The error message or exception
    # @return [void]
    def fail!(error)
      message = error.is_a?(Exception) ? "#{error.class}: #{error.message}" : error.to_s
      update!(status: :failed, error_message: message)
    end

    # Returns the human-readable label for the current step.
    #
    # @return [String]
    def current_step_label
      STEPS.dig(current_step, :label) || current_step&.humanize || "Initializing"
    end

    # Returns elapsed time since the run started.
    #
    # @return [ActiveSupport::Duration, nil]
    def elapsed_time
      return nil unless running? || completed? || failed?

      (completed? || failed? ? updated_at : Time.current) - created_at
    end

    # Formats elapsed time for display.
    #
    # @return [String]
    def elapsed_time_formatted
      seconds = elapsed_time&.to_i || 0
      if seconds < 60
        "#{seconds}s"
      elsif seconds < 3600
        "#{seconds / 60}m #{seconds % 60}s"
      else
        "#{seconds / 3600}h #{(seconds % 3600) / 60}m"
      end
    end

    # Returns a hash for JSON API response.
    #
    # @return [Hash]
    def as_json(options = {})
      {
        id: id,
        status: status,
        current_step: current_step,
        current_step_label: current_step_label,
        progress: progress,
        examples_processed: examples_processed,
        total_examples: total_examples,
        elapsed_time: elapsed_time_formatted,
        error_message: error_message,
        prompt_id: prompt_id,
        prompt_name: prompt_name
      }
    end
  end
end
