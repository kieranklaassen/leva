# frozen_string_literal: true

module Leva
  class WorkbenchController < ApplicationController
    include ApplicationHelper

    before_action :set_prompt, only: [ :index, :edit, :update, :run, :run_all_evals, :run_evaluator ]
    before_action :set_dataset_record, only: [ :index, :run, :run_all_evals, :run_evaluator ]
    before_action :set_runner_result, only: [ :index, :run_all_evals, :run_evaluator ]

    # GET /workbench
    # @return [void]
    def index
      @prompts = Prompt.all
      @selected_prompt = @prompt || Prompt.first
      @evaluators = load_evaluators
      @runners = load_runners
      @selected_runner = params[:runner] || @runners.first&.name
      @selected_dataset_record = params[:dataset_record_id] || DatasetRecord.first&.id

      # Get merged context if runner and dataset record are available
      if @selected_runner && @dataset_record && valid_runner?(@selected_runner)
        runner_class = @selected_runner.constantize
        runner = runner_class.new
        @record_context = @dataset_record.recordable.to_llm_context
        @runner_context = runner.to_llm_context(@dataset_record.recordable)
        @merged_context = @record_context.merge(@runner_context)
      end
    end

    # GET /workbench/new
    # @return [void]
    def new
      @prompt = Prompt.new
      @predefined_prompts = load_predefined_prompts
    end

    # POST /workbench
    # @return [void]
    def create
      @prompt = Prompt.new(prompt_params)
      if @prompt.save
        redirect_to workbench_index_path(prompt_id: @prompt.id), notice: "Prompt was successfully created."
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
        render json: { status: "success", message: "Prompt updated successfully" }
      else
        render json: { status: "error", errors: @prompt.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def run
      return redirect_to workbench_index_path, alert: "Please select a record and a runner" unless @dataset_record && run_params[:runner]

      return redirect_to workbench_index_path, alert: "Invalid runner selected" unless valid_runner?(run_params[:runner])
      runner_class = run_params[:runner].constantize

      runner = runner_class.new
      runner_result = runner.execute_and_store(nil, @dataset_record, @prompt)

      redirect_to workbench_index_path(prompt_id: @prompt.id, dataset_record_id: @dataset_record.id, runner: run_params[:runner]), notice: "Run completed successfully"
    end

    def run_all_evals
      return redirect_to workbench_index_path, alert: "No runner result available" unless @runner_result

      load_evaluators.each do |evaluator_class|
        evaluator = evaluator_class.new
        evaluator.evaluate_and_store(nil, @runner_result)
      end

      redirect_to workbench_index_path(prompt_id: @prompt.id, dataset_record_id: @dataset_record.id, runner: params[:runner]), notice: "All evaluations completed successfully"
    end

    def run_evaluator
      return redirect_to workbench_index_path, alert: "No runner result available" unless @runner_result

      return redirect_to workbench_index_path, alert: "Invalid evaluator selected" unless allowed_evaluator_names.include?(params[:evaluator])
      evaluator_class = params[:evaluator].constantize

      evaluator = evaluator_class.new
      evaluator.evaluate_and_store(nil, @runner_result)

      redirect_to workbench_index_path(prompt_id: @prompt.id, dataset_record_id: @dataset_record.id, runner: params[:runner]), notice: "Evaluator run successfully"
    end

    private

    def set_prompt
      @prompt = params[:prompt_id] ? Prompt.find(params[:prompt_id]) : Prompt.first
    end

    def prompt_params
      params.require(:prompt).permit(:name, :system_prompt, :user_prompt, :version)
    end

    def set_dataset_record
      @dataset_record = DatasetRecord.find_by(id: params[:dataset_record_id]) || DatasetRecord.first
    end

    def run_params
      params.permit(:runner, :prompt_id, :dataset_record_id)
    end

    def set_runner_result
      @runner_result = @dataset_record.runner_results.last if @dataset_record
    end

    def allowed_runner_names
      @allowed_runner_names ||= load_runners.map(&:name)
    end

    def allowed_evaluator_names
      @allowed_evaluator_names ||= load_evaluators.map(&:name)
    end

    def valid_runner?(runner_name)
      return true if allowed_runner_names.include?(runner_name)

      # Also accept any class that inherits from BaseRun (for testing)
      klass = runner_name.constantize
      klass < Leva::BaseRun
    rescue NameError
      false
    end
  end
end
