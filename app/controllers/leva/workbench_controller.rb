# frozen_string_literal: true

module Leva
  class WorkbenchController < ApplicationController
    before_action :set_prompt, only: [:index, :edit, :update, :run]
    before_action :load_evaluators, only: [:index]
    before_action :load_runners, only: [:index, :run]
    before_action :load_predefined_prompts, only: [:new, :create]
    before_action :set_dataset_record, only: [:index, :run]

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
      return redirect_to workbench_index_path, alert: 'Please select a record and a runner' unless @dataset_record && run_params[:runner]

      runner_class = run_params[:runner].constantize
      return redirect_to workbench_index_path, alert: 'Invalid runner selected' unless runner_class < Leva::BaseRun

      runner = runner_class.new

      record = @dataset_record.recordable
      prompt_template = Liquid::Template.parse(@prompt.user_prompt)
      context = record.to_llm_context.stringify_keys
      parsed_prompt = prompt_template.render(context)

      result = runner.execute(record)

      flash[:result] = result
      redirect_to workbench_index_path(prompt_id: @prompt.id, dataset_record_id: @dataset_record.id, runner: run_params[:runner]), notice: 'Run completed successfully'
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

    def set_dataset_record
      @dataset_record = DatasetRecord.find(params[:dataset_record_id]) if params[:dataset_record_id]
    end

    def load_runners
      @runners = Dir[Rails.root.join('app', 'runners', '*.rb')].map do |file|
        File.basename(file, '.rb').camelize.constantize
      end.select { |klass| klass < Leva::BaseRun }
    end

    def run_params
      params.permit(:runner)
    end
  end
end