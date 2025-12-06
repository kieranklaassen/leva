# frozen_string_literal: true

module Leva
  class DatasetOptimizationsController < ApplicationController
    before_action :set_dataset

    # GET /datasets/:dataset_id/optimization/new
    # Shows the prompt optimization form
    # @return [void]
    def new
      @record_count = @dataset.dataset_records.count
      @prompt_optimizer = PromptOptimizer.new(dataset: @dataset)
      @can_optimize = @prompt_optimizer.can_optimize?
      @records_needed = @prompt_optimizer.records_needed
      @modes = PromptOptimizer::MODES
      @models = PromptOptimizer.available_models
      @optimizers = PromptOptimizer::OPTIMIZERS
    end

    # POST /datasets/:dataset_id/optimization
    # Starts the prompt optimization job with progress tracking
    # @return [void]
    def create
      opt_params = optimization_params

      @optimization_run = @dataset.optimization_runs.create!(
        prompt_name: opt_params[:prompt_name],
        mode: opt_params[:mode],
        model: opt_params[:model],
        optimizer: opt_params[:optimizer],
        status: :pending
      )

      PromptOptimizationJob.perform_later(optimization_run_id: @optimization_run.id)

      redirect_to optimization_run_path(@optimization_run)
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    # @return [void]
    def set_dataset
      @dataset = Dataset.find(params[:dataset_id])
    end

    # Strong parameters for optimization run creation.
    # @return [Hash]
    # @raise [ActionController::BadRequest] If model is invalid
    def optimization_params
      model = params[:model].presence || PromptOptimizer::DEFAULT_MODEL
      unless PromptOptimizer.find_model(model)
        raise ActionController::BadRequest, "Invalid model: #{model}"
      end

      {
        prompt_name: params[:prompt_name].presence || "Optimized: #{@dataset.name}",
        mode: params[:mode].presence || "light",
        model: model,
        optimizer: params[:optimizer].presence || PromptOptimizer::DEFAULT_OPTIMIZER.to_s
      }
    end
  end
end
