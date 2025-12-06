# frozen_string_literal: true

module Leva
  class ExperimentsController < ApplicationController
    before_action :set_experiment, only: [ :show, :edit, :update ]
    before_action :check_editable, only: [ :edit, :update ]
    before_action :load_runners_and_evaluators, only: [ :new, :edit, :create, :update ]

    # GET /experiments
    # @return [void]
    def index
      @experiments = Experiment.includes(:evaluation_results).all
      @evaluator_classes = Leva::EvaluationResult.distinct.pluck(:evaluator_class)
    end

    # GET /experiments/1
    # @return [void]
    def show
      @experiment = Experiment.includes(runner_results: :evaluation_results).find(params[:id])
    end

    # GET /experiments/new
    # @return [void]
    def new
      @experiment = Experiment.new(dataset_id: params[:dataset_id])
    end

    # GET /experiments/1/edit
    # @return [void]
    def edit
      # The @experiment is already set by the before_action
    end

    # POST /experiments
    # @return [void]
    def create
      @experiment = Experiment.new(experiment_params)

      if @experiment.save
        ExperimentJob.perform_later(@experiment) unless @experiment.completed?
        redirect_to @experiment, notice: "Experiment was successfully created and is now running."
      else
        render :new
      end
    end

    # PATCH/PUT /experiments/1
    # @return [void]
    def update
      if @experiment.update(experiment_params)
        redirect_to @experiment, notice: "Experiment was successfully updated."
      else
        render :edit
      end
    end

    # POST /experiments/1/rerun
    # @return [void]
    def rerun
      @experiment = Experiment.find(params[:id])

      # Delete existing runner results and evaluation results
      @experiment.runner_results.destroy_all

      # Reset experiment status to pending
      @experiment.update(status: :pending)

      # Queue the job again
      ExperimentJob.perform_later(@experiment)

      redirect_to @experiment, notice: "Experiment has been reset and is now running again."
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    # @return [void]
    def set_experiment
      @experiment = Experiment.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    # @return [ActionController::Parameters]
    def experiment_params
      permitted = params.require(:experiment).permit(:name, :description, :dataset_id, :prompt_id, :runner_class, evaluator_classes: [], metadata: {})
      # Ensure metadata is a hash, not ActionController::Parameters
      if permitted[:metadata].present?
        metadata_hash = permitted[:metadata].to_h
        if metadata_hash.to_json.bytesize > 100_000
          raise ActionController::BadRequest, "Metadata exceeds maximum size of 100KB"
        end
        permitted[:metadata] = metadata_hash
      end
      permitted
    end

    def load_runners_and_evaluators
      @runners = Leva::ClassLoader.runners
      @evaluators = Leva::ClassLoader.evaluators
    end

    def check_editable
      redirect_to @experiment, alert: "Completed experiments cannot be edited." if @experiment.completed?
    end
  end
end
