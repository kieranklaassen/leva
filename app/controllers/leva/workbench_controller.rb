# frozen_string_literal: true

module Leva
  class WorkbenchController < ApplicationController
    before_action :set_prompt, only: [:index, :edit, :update]
    before_action :load_evaluators, only: [:index]
    before_action :load_predefined_prompts, only: [:new, :create]

    # GET /workbench
    # @return [void]
    def index
      @prompts = Prompt.all
      @selected_prompt = @prompt || Prompt.first
    end

    # GET /workbench/new
    # @return [void]
    def new
      @prompt = Prompt.new
    end

    # POST /workbench
    # @return [void]
    def create
      @prompt = Prompt.new(prompt_params)
      if @prompt.save
        redirect_to workbench_index_path(prompt_id: @prompt.id), notice: 'Prompt was successfully created.'
      else
        render :new
      end
    end

    # GET /workbench/1
    # @return [void]
    def edit
    end

    # PATCH/PUT /workbench/1
    # @return [void]
    def update
      @prompt = Prompt.find(params[:id])
      if @prompt.update(prompt_params)
        render json: { status: 'success', message: 'Prompt updated successfully' }
      else
        render json: { status: 'error', errors: @prompt.errors.full_messages }, status: :unprocessable_entity
      end
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

    private

    def set_prompt
      @prompt = params[:prompt_id] ? Prompt.find(params[:prompt_id]) : Prompt.first
    end

    def prompt_params
      params.require(:prompt).permit(:name, :system_prompt, :user_prompt, :version)
    end

    def load_evaluators
      @evaluators = Dir[Rails.root.join('app', 'evals', '*.rb')].map do |file|
        File.basename(file, '.rb').camelize.constantize
      end.select { |klass| klass < Leva::BaseEval }
    end

    def load_predefined_prompts
      @predefined_prompts = Dir.glob(Rails.root.join('app', 'prompts', '*.md')).map do |file|
        name = File.basename(file, '.md').titleize
        content = File.read(file)
        [name, content]
      end
    end
  end
end