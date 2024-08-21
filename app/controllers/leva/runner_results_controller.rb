module Leva
  class RunnerResultsController < ApplicationController
    def show
      @experiment = Experiment.find(params[:experiment_id])
      @runner_result = @experiment.runner_results.find(params[:id])
    end
  end
end