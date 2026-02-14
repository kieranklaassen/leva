# frozen_string_literal: true

require "test_helper"

module Leva
  class ExperimentsControllerTest < ActionDispatch::IntegrationTest
    test "show displays failed message when experiment has failed status and no results" do
      dataset = Dataset.create!(name: "Test Dataset")
      experiment = Experiment.create!(
        name: "Failed Experiment",
        dataset: dataset,
        runner_class: "SentimentRun",
        evaluator_classes: [ "SentimentAccuracyEval" ],
        status: :failed
      )

      get leva.experiment_path(experiment)

      assert_response :success
      assert_match(/Experiment failed/, response.body)
    end
  end
end
