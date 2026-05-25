# frozen_string_literal: true

module Leva
  # Triggers and displays dataset fine-tunes. Thin controller mirroring
  # {Leva::DatasetOptimizationsController} / {Leva::OptimizationRunsController}.
  class FineTuneRunsController < ApplicationController
    before_action :set_dataset, only: [ :create ]
    before_action :set_fine_tune_run, only: [ :show ]

    # POST /datasets/:dataset_id/fine_tune_runs
    # Starts a fine-tune for the dataset and enqueues the job.
    # @return [void]
    def create
      unless authorized_to_fine_tune?
        return redirect_to dataset_path(@dataset), alert: "You are not authorized to start a fine-tune."
      end

      base_model = params[:base_model].presence || FineTuneRun::DEFAULT_BASE_MODEL
      unless FineTuneRun::SUPPORTED_BASE_MODELS.include?(base_model)
        return redirect_to dataset_path(@dataset), alert: "Unsupported base model: #{base_model}"
      end

      @fine_tune_run = @dataset.fine_tune_runs.create!(base_model: base_model, provider: "together", status: :pending)
      FineTuneJob.perform_later(fine_tune_run_id: @fine_tune_run.id)
      redirect_to fine_tune_run_path(@fine_tune_run)
    end

    # GET /fine_tune_runs/:id
    # Shows fine-tune progress (HTML) or status (JSON for polling).
    # @return [void]
    def show
      respond_to do |format|
        format.html
        format.json { render json: @fine_tune_run }
      end
    end

    private

    # @return [void]
    def set_dataset
      @dataset = Dataset.find(params[:dataset_id])
    end

    # @return [void]
    def set_fine_tune_run
      @fine_tune_run = FineTuneRun.find(params[:id])
    end

    # @return [Boolean] whether the host's authorization gate allows this fine-tune
    def authorized_to_fine_tune?
      gate = Leva.config.authorize_fine_tune
      gate.nil? || gate.call(self)
    end
  end
end
