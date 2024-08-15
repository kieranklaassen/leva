# frozen_string_literal: true

module Leva
  class DatasetsController < ApplicationController
    before_action :set_dataset, only: [:show, :edit, :update, :destroy]

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
    end

    # POST /datasets
    # @return [void]
    def create
      @dataset = Dataset.new(dataset_params)

      if @dataset.save
        redirect_to @dataset, notice: 'Dataset was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /datasets/1
    # @return [void]
    def update
      if @dataset.update(dataset_params)
        redirect_to @dataset, notice: 'Dataset was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /datasets/1
    # @return [void]
    def destroy
      @dataset.destroy
      redirect_to datasets_url, notice: 'Dataset was successfully destroyed.'
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