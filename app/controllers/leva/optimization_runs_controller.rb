# frozen_string_literal: true

module Leva
  class OptimizationRunsController < ApplicationController
    before_action :set_optimization_run

    # GET /optimization_runs/:id
    # Shows the optimization progress page
    # @return [void]
    def show
      respond_to do |format|
        format.html
        format.json { render json: @optimization_run }
      end
    end

    private

    # @return [void]
    def set_optimization_run
      @optimization_run = OptimizationRun.find(params[:id])
    end
  end
end
