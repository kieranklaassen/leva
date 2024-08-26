# frozen_string_literal: true

module Leva
  class ExperimentJob < ApplicationJob
    queue_as :default

    # Perform the experiment by scheduling all dataset records for evaluation
    #
    # @param experiment [Experiment] The experiment to run
    # @return [void]
    def perform(experiment)
      return if experiment.completed? || experiment.running?

      experiment.update!(status: :running)

      experiment.dataset.dataset_records.each_with_index do |record, index|
        RunEvalJob.set(wait: 3.seconds * index).perform_later(experiment.id, record.id)
      end
    end
  end
end