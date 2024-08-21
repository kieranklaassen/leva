# frozen_string_literal: true

module Leva
  class BaseEval
    class << self
      attr_reader :dataset_record_class_name

      # Set the dataset record class for the eval
      # @param class_name [String] The name of the dataset record class
      def leva_dataset_record_class(class_name)
        @dataset_record_class_name = class_name
      end

      # Run the experiment
      # @param experiment [Leva::Experiment] The experiment to run
      def run_experiment(experiment)
        new.run_experiment(experiment)
      end
    end

    # Run the experiment
    # @param experiment [Leva::Experiment] The experiment to run
    def run_experiment(experiment)
      @experiment = experiment
      @experiment.update(status: :running)

      @experiment.dataset.records.each do |record|
        run_evaluation(record)
      end

      @experiment.update(status: :completed)
    rescue StandardError => e
      @experiment.update(status: :failed)
      Rails.logger.error "Error in experiment #{@experiment.name}: #{e.message}"
    end

    # Run the evaluation for a single record
    # @param record [ActiveRecord::Base] The record to evaluate
    # @return [Float] The score of the evaluation
    def run_evaluation(record)
      unless record.class.name == self.class.dataset_record_class_name
        raise ArgumentError, "Record class #{record.class.name} does not match expected class #{self.class.dataset_record_class_name}"
      end

      result = evaluate(record)
      save_result(record, result)
    end

    # Evaluate the record
    # @param record [ActiveRecord::Base] The record to evaluate
    # @return [Float] The score of the evaluation
    def evaluate(record)
      raise NotImplementedError, "Subclasses must implement the 'evaluate' method"
    end

    # Save the result of an evaluation
    # @param record [ActiveRecord::Base] The record evaluated
    # @param result [Float] The score of the evaluation
    def save_result(record, result)
      Leva::EvaluationResult.create!(
        experiment: @experiment,
        dataset_record: Leva::DatasetRecord.find_by(recordable: record, dataset: @experiment.dataset),
        score: result,
        evaluator_class: self.class.name
      )
    end
  end
end