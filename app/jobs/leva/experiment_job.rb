# frozen_string_literal: true

module Leva
  class ExperimentJob < ApplicationJob
    queue_as :default

    # Perform the experiment
    #
    # @param experiment [Experiment] The experiment to run
    # @return [void]
    def perform(experiment)
      run = constantize_class(experiment.runner_class)
      evals = experiment.evaluator_classes.compact.reject(&:empty?).map { |klass| constantize_class(klass) }

      Leva.run_evaluation(experiment: experiment, run: run.new, evals: evals.map(&:new))

      experiment.update(status: :completed)
    rescue StandardError => e
      experiment.update(status: :failed)
      Rails.logger.error "Error in experiment #{experiment.name}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end

    private

    def constantize_class(class_name)
      class_name.constantize
    rescue NameError => e
      raise NameError, "Invalid class name: #{class_name}. Error: #{e.message}"
    end
  end
end