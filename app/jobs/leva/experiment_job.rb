# frozen_string_literal: true

module Leva
  class ExperimentJob < ApplicationJob
    queue_as :default

    # Perform the experiment
    #
    # @param experiment [Experiment] The experiment to run
    # @return [void]
    def perform(experiment)
      Rails.logger.info "Starting experiment: #{experiment.name}"

      begin
        # Update experiment status to running
        experiment.update(status: 'running')

        # Perform the experiment logic here
        # This is a placeholder for your actual experiment logic
        sleep 5 # Simulating some work

        # Update experiment status to completed
        experiment.update(status: 'completed')

        Rails.logger.info "Experiment completed: #{experiment.name}"
      rescue StandardError => e
        Rails.logger.error "Error in experiment #{experiment.name}: #{e.message}"
        experiment.update(status: 'failed')
      end
    end
  end
end