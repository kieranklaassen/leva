# frozen_string_literal: true

module Leva
  # Tracks a dataset fine-tune from pending through completed/failed and holds the
  # resulting fine-tuned model id. Mirrors {Leva::OptimizationRun} so the UX and
  # code shape stay consistent.
  #
  # @example
  #   run = FineTuneRun.create!(dataset: dataset, base_model: FineTuneRun::DEFAULT_BASE_MODEL)
  #   run.start!
  #   run.update_progress(step: "training", progress: 60)
  #   run.complete!(result: { model_id: "kieran/Qwen3-8B-ft-1", serving_base_url: "https://api.together.xyz/v1" })
  class FineTuneRun < ApplicationRecord
    self.table_name = "leva_fine_tune_runs"

    # Minimum dataset records required to start a fine-tune.
    MINIMUM_RECORDS = 10

    # Default base model fine-tuned when none is chosen (verified on Together).
    DEFAULT_BASE_MODEL = "Qwen/Qwen2.5-7B-Instruct"

    # Base models offered for fine-tuning. Reflects Together's LoRA-capable
    # catalog; update as Together's supported models change.
    SUPPORTED_BASE_MODELS = [
      "Qwen/Qwen3-8B",
      "Qwen/Qwen3-4B",
      "Qwen/Qwen2.5-7B-Instruct",
      "google/gemma-2-9b-it"
    ].freeze

    # Display metadata for each fine-tune step.
    STEPS = {
      "exporting" => { label: "Exporting dataset", icon: "download" },
      "uploading" => { label: "Uploading training file", icon: "upload" },
      "creating_job" => { label: "Creating fine-tune job", icon: "zap" },
      "training" => { label: "Training model", icon: "cpu" },
      "completed" => { label: "Complete", icon: "check-circle" }
    }.freeze

    belongs_to :dataset

    enum :status, {
      pending: "pending",
      running: "running",
      completed: "completed",
      failed: "failed"
    }, default: :pending

    validates :provider, presence: true
    validates :base_model, presence: true, inclusion: { in: SUPPORTED_BASE_MODELS }
    validates :progress, numericality: { in: 0..100 }

    # Marks the run as started.
    # @return [void]
    def start!
      update!(status: :running, current_step: "exporting", progress: 0)
    end

    # Updates progress for live UI.
    # @param step [String]
    # @param progress [Integer]
    # @return [void]
    def update_progress(step:, progress:)
      update!(current_step: step, progress: progress)
    end

    # Marks the run completed and stores the fine-tuned model's serving binding.
    # @param result [Hash] the U1 adapter result ({ model_id:, serving_base_url:, serving_endpoint_id: })
    # @return [void]
    def complete!(result:)
      update!(
        status: :completed,
        fine_tuned_model_id: result[:model_id],
        serving_base_url: result[:serving_base_url],
        serving_endpoint_id: result[:serving_endpoint_id],
        current_step: "completed",
        progress: 100
      )
    end

    # Marks the run failed with a sanitized, single-line error message so provider
    # response bodies (which can echo uploaded training content) are not persisted.
    # @param error [String, Exception]
    # @return [void]
    def fail!(error)
      message = error.is_a?(Exception) ? "#{error.class}: #{error.message}" : error.to_s
      update!(status: :failed, error_message: sanitize_error(message))
    end

    # @return [String] human-readable label for the current step
    def current_step_label
      STEPS.dig(current_step, :label) || current_step&.humanize || "Initializing"
    end

    # @return [ActiveSupport::Duration, nil]
    def elapsed_time
      return nil unless running? || completed? || failed?

      (completed? || failed? ? updated_at : Time.current) - created_at
    end

    # @return [String] elapsed time formatted for display
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

    # @return [Hash] JSON representation for the progress poller
    def as_json(_options = {})
      {
        id: id,
        status: status,
        current_step: current_step,
        current_step_label: current_step_label,
        progress: progress,
        base_model: base_model,
        fine_tuned_model_id: fine_tuned_model_id,
        elapsed_time: elapsed_time_formatted,
        error_message: error_message
      }
    end

    private

    # @param message [String]
    # @return [String] first line, stripped and truncated
    def sanitize_error(message)
      message.to_s.lines.first.to_s.strip.truncate(500)
    end
  end
end
