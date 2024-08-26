# frozen_string_literal: true

module Leva
  class ExperimentJob < ApplicationJob
    queue_as :default

    # Maximum number of concurrent jobs
    MAX_CONCURRENCY = 5

    # Perform the experiment
    #
    # @param experiment [Experiment] The experiment to run
    # @return [void]
    def perform(experiment)
      return if experiment.completed? || experiment.running?

      experiment.update!(status: :running)

      dataset_record_ids = experiment.dataset.dataset_records.pluck(:id)
      total_records = dataset_record_ids.size

      dataset_record_ids.each_slice(MAX_CONCURRENCY) do |batch_ids|
        batch_ids.each do |record_id|
          RunEvalJob.perform_later(experiment.id, record_id)
        end
        wait_for_jobs(experiment)
      end

      experiment.update!(status: :completed) if experiment.runner_results.count == total_records
    end

    private

    def wait_for_jobs(experiment)
      loop do
        break if Leva::RunEvalJob.queue_adapter.enqueued_jobs.empty? &&
                 Leva::RunEvalJob.queue_adapter.performed_jobs.size % MAX_CONCURRENCY == 0
        sleep 1
      end
    end
  end
end