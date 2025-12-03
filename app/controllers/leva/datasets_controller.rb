# frozen_string_literal: true

module Leva
  class DatasetsController < ApplicationController
    before_action :set_dataset, only: [ :show, :edit, :update, :destroy, :optimize, :run_optimization ]

    # GET /datasets
    # @return [void]
    def index
      @datasets = Dataset.all
    end

    # GET /datasets/1
    # @return [void]
    def show
      @experiments = @dataset.experiments
      @new_experiment = Experiment.new(dataset: @dataset)
    end

    # GET /datasets/new
    # @return [void]
    def new
      @dataset = Dataset.new
    end

    # GET /datasets/1/edit
    # @return [void]
    def edit
      # The @dataset is already set by the before_action
    end

    # POST /datasets
    # @return [void]
    def create
      @dataset = Dataset.new(dataset_params)

      if @dataset.save
        redirect_to @dataset, notice: "Dataset was successfully created."
      else
        render :new
      end
    end

    # PATCH/PUT /datasets/1
    # @return [void]
    def update
      if @dataset.update(dataset_params)
        redirect_to @dataset, notice: "Dataset was successfully updated."
      else
        render :edit
      end
    end

    # DELETE /datasets/1
    # @return [void]
    def destroy
      if @dataset.dataset_records.any?
        redirect_to @dataset, alert: "Cannot delete dataset with existing records."
      else
        @dataset.destroy
        redirect_to datasets_url, notice: "Dataset was successfully destroyed."
      end
    end

    # GET /datasets/1/optimize
    # Shows the prompt optimization form
    # @return [void]
    def optimize
      @record_count = @dataset.dataset_records.count
      @optimizer = PromptOptimizer.new(dataset: @dataset)
      @can_optimize = @optimizer.can_optimize?
      @records_needed = @optimizer.records_needed
      @modes = PromptOptimizer::MODES
    end

    # POST /datasets/1/run_optimization
    # Starts the prompt optimization job
    # @return [void]
    def run_optimization
      prompt_name = params[:prompt_name].presence || "Optimized: #{@dataset.name}"
      mode = params[:mode]&.to_sym || :light

      PromptOptimizationJob.perform_later(
        dataset_id: @dataset.id,
        prompt_name: prompt_name,
        mode: mode
      )

      redirect_to @dataset, notice: "Prompt optimization started. A new prompt will be created when complete."
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    # @return [void]
    def set_dataset
      @dataset = Dataset.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    # @return [ActionController::Parameters]
    def dataset_params
      params.require(:dataset).permit(:name, :description)
    end
  end
end
