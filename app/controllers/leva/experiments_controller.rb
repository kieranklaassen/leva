# frozen_string_literal: true

module Leva
  class ExperimentsController < ApplicationController
    include ApplicationHelper

    before_action :set_experiment, only: [:show, :edit, :update]
    before_action :check_editable, only: [:edit, :update]
    before_action :load_runners_and_evaluators, only: [:new, :edit, :create, :update]

    # GET /experiments
    # @return [void]
    def index
      @experiments = Experiment.all
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
        ExperimentJob.perform_later(@experiment)
        redirect_to @experiment, notice: 'Experiment was successfully created and is now running.'
      else
        render :new
      end
    end

    # PATCH/PUT /experiments/1
    # @return [void]
    def update
      if @experiment.update(experiment_params)
        redirect_to @experiment, notice: 'Experiment was successfully updated.'
      else
        render :edit
      end
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
      params.require(:experiment).permit(:name, :description, :dataset_id, :prompt_id, :runner_class, evaluator_classes: [])
    end

    def load_runners_and_evaluators
      @runners = load_runners
      @evaluators = load_evaluators
    end

    def check_editable
      redirect_to @experiment, alert: 'Completed experiments cannot be edited.' if @experiment.completed?
    end
  end
end