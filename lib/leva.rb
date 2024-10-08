require "leva/version"
require "leva/engine"
require "liquid"

module Leva
  # Runs an evaluation experiment with the given run and evals.
  #
  # @param experiment [Leva::Experiment] The experiment to run.
  # @param run [Leva::BaseRun] The run implementation to use.
  # @param evals [Array<Leva::BaseEval>] The evaluation implementations to use.
  # @return [void]
  def self.run_evaluation(experiment:, run:, evals:)
    experiment.update(status: :running)

    experiment.dataset.dataset_records.find_each do |dataset_record|
      runner_result = run.execute_and_store(experiment, dataset_record, experiment.prompt)

      evals.each do |eval|
        eval.evaluate_and_store(experiment, runner_result)
      end
    end

    experiment.update(status: :completed)
  rescue StandardError => e
    experiment.update(status: :failed)
    Rails.logger.error "Error in experiment #{experiment.name}: #{e.message}"
  end

  # Runs a single evaluation for a dataset record
  #
  # @param experiment [Leva::Experiment] The experiment to run.
  # @param run [Leva::BaseRun] The run implementation to use.
  # @param evals [Array<Leva::BaseEval>] The evaluation implementations to use.
  # @param dataset_record [Leva::DatasetRecord] The dataset record to process.
  # @return [void]
  def self.run_single_evaluation(experiment:, run:, evals:, dataset_record:)
    runner_result = run.execute_and_store(experiment, dataset_record, experiment.prompt)

    evals.each do |eval|
      eval.evaluate_and_store(experiment, runner_result)
    end
  end

  # Base class for all run implementations in Leva.
  #
  # @abstract Subclass and override {#execute} to implement
  #   custom run logic.
  class BaseRun
    # Executes the run on a given record.
    #
    # @param record [Leva::DatasetRecord] The record to run the model on.
    # @return [Object] The output of the model execution.
    # @raise [NotImplementedError] if the method is not implemented in a subclass.
    def execute(record)
      raise NotImplementedError, "#{self.class} must implement #execute"
    end

    # Executes the run on a given dataset record and stores the result.
    #
    # @param experiment [Leva::Experiment, nil] The experiment being run, if any.
    # @param dataset_record [Leva::DatasetRecord] The dataset record to run the model on.
    # @param prompt [Leva::Prompt] The prompt to store the version of.
    # @return [Leva::RunnerResult] The stored runner result.
    def execute_and_store(experiment, dataset_record, prompt)
      # Expose these to the subclass execution
      @experiment = experiment
      @prompt = prompt

      result = execute(dataset_record.recordable)
      RunnerResult.create!(
        experiment: experiment,
        dataset_record: dataset_record,
        prompt: prompt,
        prediction: result,
        runner_class: self.class.name
      )
    end

    # @param runner_result [Leva::RunnerResult] The runner result to parse
    # @return [Array<String>] The parsed predictions
    def parsed_predictions(runner_result)
      if extract_regex_pattern(runner_result)
        runner_result.prediction.scan(extract_regex_pattern(runner_result)).map { |match| match.first&.strip }.compact
      else
        [runner_result.prediction]
      end
    end

    # @param runner_result [Leva::RunnerResult] The runner result to extract regex from
    # @return [Regexp, nil] The regex pattern to use for parsing predictions
    def extract_regex_pattern(runner_result)
      runner_result.dataset_record.recordable.extract_regex_pattern if runner_result.dataset_record.recordable.respond_to?(:extract_regex_pattern)
    end

    # @param runner_result [Leva::RunnerResult] The runner result to get ground truth from
    # @return [String] The ground truth for the runner result
    def ground_truth(runner_result)
      runner_result.dataset_record.ground_truth
    end
  end

  # Base class for all evaluation implementations in Leva.
  #
  # @abstract Subclass and override {#evaluate} to implement
  #   custom evaluation logic.
  class BaseEval
    # Evaluates the model's prediction against the ground truth.
    #
    # @param prediction [Object] The model's prediction.
    # @param recordable [Object] The recordable object containing the ground truth.
    # @return [Float] The evaluation score.
    # @raise [NotImplementedError] if the method is not implemented in a subclass.
    def evaluate(prediction, recordable)
      raise NotImplementedError, "#{self.class} must implement #evaluate"
    end

    # Evaluates a single runner result and stores the evaluation.
    #
    # @param experiment [Leva::Experiment, nil] The experiment being evaluated, if any.
    # @param runner_result [Leva::RunnerResult] The runner result to evaluate.
    # @return [Leva::EvaluationResult] The stored evaluation result.
    def evaluate_and_store(experiment, runner_result)
      @experiment = experiment
      @runner_result = runner_result

      score = evaluate(runner_result, runner_result.dataset_record.recordable)

      EvaluationResult.create!(
        experiment: experiment,
        dataset_record: runner_result.dataset_record,
        runner_result: runner_result,
        score: score,
        evaluator_class: self.class.name
      )
    end
  end
end