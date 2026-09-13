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

    test "the new experiment form proposes the host's default model" do
      original = Leva.config.instance_variable_get(:@default_model)
      Leva.config.default_model = -> { "claude-sonnet-4-5" }
      Dataset.create!(name: "Test Dataset")

      get leva.new_experiment_path

      assert_response :success
      assert_includes response.body, %(data-searchable-select-selected-value="claude-sonnet-4-5")
    ensure
      Leva.config.default_model = original
    end

    test "the layout serves Stimulus from the engine's own assets, not a CDN" do
      get leva.experiments_path

      assert_response :success
      assert_match %r{<script src="/assets/leva/stimulus\.umd[^"]*\.js"}, response.body
      assert_no_match(/cdn\.jsdelivr\.net/, response.body)
    end
  end
end
