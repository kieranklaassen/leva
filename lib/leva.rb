require "leva/version"
require "leva/engine"

module Leva
  # Runs an evaluation experiment with the given run and evals.
  #
  # @param experiment [Leva::Experiment] The experiment to run.
  # @param run [Leva::BaseRun] The run implementation to use.
  # @param evals [Array<Leva::BaseEval>] The evaluation implementations to use.
  # @return [void]
  def self.run_evaluation(experiment:, run:, evals:)
    results = run.run(experiment)
    evals.each do |eval|
      eval.evaluate_all(experiment, results)
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

    # Runs the model on all records in an experiment.
    #
    # @param experiment [Leva::Experiment] The experiment to run.
    # @return [Hash] A hash mapping dataset_record_ids to their execution results.
    def run(experiment)
      results = {}
      experiment.dataset.dataset_records.find_each do |dataset_record|
        result = execute(dataset_record.recordable)
        results[dataset_record.id] = result
      end
      results
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
    # @return [Leva::Result] The evaluation result.
    # @raise [NotImplementedError] if the method is not implemented in a subclass.
    def evaluate(prediction, record)
      raise NotImplementedError, "#{self.class} must implement #evaluate"
    end

    # Evaluates all results for an experiment.
    #
    # @param experiment [Leva::Experiment] The experiment to evaluate.
    # @param results [Hash] A hash mapping dataset_record_ids to their execution results.
    # @return [void]
    def evaluate_all(experiment, results)
      experiment.dataset.dataset_records.find_each do |dataset_record|
        prediction = results[dataset_record.id]
        evaluation = evaluate(prediction, dataset_record.recordable)

        Leva::EvaluationResult.create!(
          experiment: experiment,
          dataset_record: dataset_record,
          prediction: prediction,
          score: evaluation.score,
          label: evaluation.label
        )
      end
    end
  end

  # Represents the result of an evaluation
  class Result
    attr_reader :label, :prediction, :score

    # Initialize a new Result
    # @param label [String] The label for the result
    # @param score [Float] The score of the evaluation (0.0 to 1.0)
    def initialize(label:, score:)
      @label = label
      @score = score
    end
  end
end