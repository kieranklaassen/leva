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
    experiment.dataset.dataset_records.find_each do |dataset_record|
      # Run the runner for this dataset record
      runner_result = run.execute_and_store(experiment, dataset_record)

      # Evaluate the runner result with each evaluator
      evals.each do |eval|
        eval.evaluate_and_store(experiment, runner_result)
      end
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
    # @param experiment [Leva::Experiment] The experiment being run.
    # @param dataset_record [Leva::DatasetRecord] The dataset record to run the model on.
    # @return [Leva::RunnerResult] The stored runner result.
    def execute_and_store(experiment, dataset_record)
      result = execute(dataset_record.recordable)
      RunnerResult.create!(
        experiment: experiment,
        dataset_record: dataset_record,
        prediction: result
      )
    end
  end

  # Base class for all evaluation implementations in Leva.
  #
  # @abstract Subclass and override {#evaluate} to implement
  #   custom evaluation logic.
  class BaseEval
    # Evaluates the model's prediction against the expected result.
    #
    # @param prediction [Object] The model's prediction.
    # @param record [Object] The expected result.
    # @return [Float] The evaluation score.
    # @raise [NotImplementedError] if the method is not implemented in a subclass.
    def evaluate(prediction, record)
      raise NotImplementedError, "#{self.class} must implement #evaluate"
    end

    # Evaluates a single runner result and stores the evaluation.
    #
    # @param experiment [Leva::Experiment] The experiment being evaluated.
    # @param runner_result [Leva::RunnerResult] The runner result to evaluate.
    # @return [Leva::EvaluationResult] The stored evaluation result.
    def evaluate_and_store(experiment, runner_result)
      score = evaluate(runner_result.prediction, runner_result.dataset_record.recordable)

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