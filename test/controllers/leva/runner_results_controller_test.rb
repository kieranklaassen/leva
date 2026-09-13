# frozen_string_literal: true

require "test_helper"

module Leva
  class RunnerResultsControllerTest < ActionDispatch::IntegrationTest
    setup do
      text = TextContent.create!(text: "I love this", expected_label: "positive")
      dataset = Dataset.create!(name: "Results dataset")
      record = dataset.dataset_records.create!(recordable: text)
      @experiment = Experiment.create!(name: "Prompt-less experiment", dataset: dataset, runner_class: "SentimentRun",
                                       evaluator_classes: [ "SentimentAccuracyEval" ], status: :completed)
      @runner_result = RunnerResult.create!(experiment: @experiment, dataset_record: record, prediction: "positive", runner_class: "SentimentRun")
      EvaluationResult.create!(experiment: @experiment, dataset_record: record, runner_result: @runner_result, score: 1.0,
                               evaluator_class: "SentimentAccuracyEval", details: "prediction 'positive' equals the expected label")
    end

    test "a result without a prompt renders, with the evaluator's details" do
      get leva.experiment_runner_result_path(@experiment, @runner_result)

      assert_response :success
      assert_match(/The runner owns its prompt/, response.body)
      assert_match(/prediction &#39;positive&#39; equals the expected label/, response.body)
    end

    test "the experiment table carries the details as the score's tooltip" do
      get leva.experiment_path(@experiment)

      assert_response :success
      assert_match(/title="prediction &#39;positive&#39; equals the expected label"/, response.body)
    end
  end
end
