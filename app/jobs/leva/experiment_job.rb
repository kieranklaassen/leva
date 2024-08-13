# frozen_string_literal: true

module Leva
  class ExperimentJob < ApplicationJob
    queue_as :default

    # Perform the experiment
    #
    # @param experiment [Experiment] The experiment to run
    # @return [void]
    def perform(eval, record)
      result = eval.run_each(record)
      eval.save_result(result)
    end
  end
end