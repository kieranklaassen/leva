# frozen_string_literal: true

module Leva
  class ExperimentsController < ApplicationController
    before_action :set_experiment, only: [:show, :edit, :update, :destroy]

    # GET /experiments
    # @return [void]
    def index
      @experiments = Experiment.all
    end

    # GET /experiments/1
    # @return [void]
    def show
    end

    # GET /experiments/new
    # @return [void]
    def new
      @experiment = Experiment.new
    end

    # GET /experiments/1/edit
    # @return [void]
    def edit
    end

    # POST /experiments
    # @return [void]
    def create
      @experiment = Experiment.new(experiment_params)

      if @experiment.save
        ExperimentJob.perform_later(@experiment)
        redirect_to @experiment, notice: 'Experiment was successfully created.'
      else
        @dataset = @experiment.dataset
        render 'leva/datasets/show'
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

    # DELETE /experiments/1
    # @return [void]
    def destroy
      @experiment.destroy
      redirect_to experiments_url, notice: 'Experiment was successfully destroyed.'
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
      params.require(:experiment).permit(:name, :description, :dataset_id, :prompt_id)
    end
  end
end