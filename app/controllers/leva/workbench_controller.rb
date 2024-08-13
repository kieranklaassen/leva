# frozen_string_literal: true

module Leva
  class WorkbenchController < ApplicationController
    # GET /workbench
    # @return [void]
    def index
      @prompts = Prompt.all
      @selected_prompt = Prompt.first || Prompt.create!(name: "Test Prompt", version: 1, system_prompt: "You are a helpful assistant.", user_prompt: "Hello, how can I help you today?")
      @evaluators = ['Evaluator 1', 'Evaluator 2', 'Evaluator 3']
    end

    # GET /workbench/new
    # @return [void]
    def new
      @experiment = Experiment.new
    end

    # GET /workbench/1
    # @return [void]
    def show
      @experiment = Experiment.find(params[:id])
    end

    def run
      # Implement the logic for running the prompt
      redirect_to workbench_index_path, notice: 'Prompt run successfully'
    end

    def run_with_evaluation
      # Implement the logic for running the prompt with evaluation
      redirect_to workbench_index_path, notice: 'Prompt run with evaluation successfully'
    end

    def run_evaluator
      # Implement the logic for running a single evaluator
      redirect_to workbench_index_path, notice: 'Evaluator run successfully'
    end
  end
end