# frozen_string_literal: true

module Leva
  class RunEvalJob < ApplicationJob
    queue_as :default

    # Perform a single run and evaluation for a dataset record
    #
    # @param experiment_id [Integer] The ID of the experiment
    # @param dataset_record_id [Integer] The ID of the dataset record
    # @return [void]
    def perform(experiment_id, dataset_record_id)
      experiment = Experiment.find(experiment_id)
      dataset_record = DatasetRecord.find(dataset_record_id)

      run = constantize_class(experiment.runner_class).new
      evals = experiment.evaluator_classes.compact.reject(&:empty?).map { |klass| constantize_class(klass).new }

      Leva.run_single_evaluation(experiment: experiment, run: run, evals: evals, dataset_record: dataset_record)
    end

    private

    def constantize_class(class_name)
      class_name.constantize
    rescue NameError => e
      raise NameError, "Invalid class name: #{class_name}. Error: #{e.message}"
    end
  end
end