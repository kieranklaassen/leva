# frozen_string_literal: true

module Leva
  class ExperimentJob < ApplicationJob
    queue_as :default

    # Perform the experiment
    #
    # @param experiment [Experiment] The experiment to run
    # @return [void]
    def perform(experiment)
      return if experiment.completed? || experiment.running?

      experiment.update!(status: :running)

      dataset_record_ids = experiment.dataset.dataset_records.pluck(:id)
      total_records = dataset_record_ids.size

      dataset_record_ids.each do |record_id|
        RunEvalJob.perform_later(experiment.id, record_id)
        # TODO: make better
        sleep(3)
      end

      experiment.reload
      experiment.update!(status: :completed) if experiment.runner_results.count == total_records
    end
  end
end