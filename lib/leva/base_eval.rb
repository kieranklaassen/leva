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
        @record = record
        unless @record.class_name == self.class.dataset_record_class_name
          raise ArgumentError, "Record class #{@record.class_name} does not match expected class #{self.class.dataset_record_class_name}"
        end
        ExperimentJob.perform_later(self, @record)
      end

      @experiment.update(status: :completed)
    rescue StandardError => e
      @experiment.update(status: :failed)
      Rails.logger.error "Error in experiment #{@experiment.name}: #{e.message}"
    end

    # Run the evaluation for a single record
    # @param record [ActiveRecord::Base] The record to evaluate
    # @return [Float] The score of the evaluation
    def run_each(record)
      raise NotImplementedError, "Subclasses must implement the 'run_each' method"
    end

    # Save the result of an evaluation
    # @param result [Float] The score of the evaluation
    def save_result(result)
      Leva::EvaluationResult.create!(
        experiment: @experiment,
        dataset_record: Leva::DatasetRecord.find_by(recordable: @record, dataset: @experiment.dataset),
        prediction: result.prediction,
        score: result.score,
        label: result.label
      )
    end
  end
end