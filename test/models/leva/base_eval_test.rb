# frozen_string_literal: true

require "test_helper"

module Leva
  class BaseEvalTest < ActiveSupport::TestCase
    class ScoreOnlyEval < Leva::BaseEval
      def evaluate(_runner_result, _recordable) = 0.75
    end

    class ArrayEval < Leva::BaseEval
      def evaluate(_runner_result, _recordable) = [ 1.0, "matched the expected label" ]
    end

    class HashEval < Leva::BaseEval
      def evaluate(_runner_result, _recordable) = { score: 0.0, details: { verdict: "fail", reason: "wrong label" } }
    end

    class AbstainingEval < Leva::BaseEval
      def evaluate(_runner_result, _recordable) = nil
    end

    class BrokenEval < Leva::BaseEval
      def evaluate(_runner_result, _recordable) = "pass"
    end

    setup do
      text = TextContent.create!(text: "Hello world", expected_label: "positive")
      @dataset = Leva::Dataset.create!(name: "Eval dataset")
      record = @dataset.dataset_records.create!(recordable: text)
      @experiment = Leva::Experiment.create!(name: "Eval experiment", dataset: @dataset, runner_class: "SentimentRun", evaluator_classes: [ "ScoreOnlyEval" ])
      @runner_result = Leva::RunnerResult.create!(experiment: @experiment, dataset_record: record, prediction: "positive", runner_class: "SentimentRun")
    end

    test "a numeric return stores the score with no details" do
      result = ScoreOnlyEval.new.evaluate_and_store(@experiment, @runner_result)

      assert result.persisted?
      assert_equal 0.75, result.score
      assert_nil result.details
      assert_equal "Leva::BaseEvalTest::ScoreOnlyEval", result.evaluator_class
    end

    test "an array return stores the score and the details" do
      result = ArrayEval.new.evaluate_and_store(@experiment, @runner_result)

      assert_equal 1.0, result.score
      assert_equal "matched the expected label", result.details
    end

    test "a hash return stores the score and serializes structured details as JSON" do
      result = HashEval.new.evaluate_and_store(@experiment, @runner_result)

      assert_equal 0.0, result.score
      assert_equal({ "verdict" => "fail", "reason" => "wrong label" }, JSON.parse(result.details))
    end

    test "a nil return abstains: nothing is stored" do
      assert_no_difference("Leva::EvaluationResult.count") do
        assert_nil AbstainingEval.new.evaluate_and_store(@experiment, @runner_result)
      end
    end

    test "any other return is a programming error named after the evaluator" do
      error = assert_raises(ArgumentError) { BrokenEval.new.evaluate_and_store(@experiment, @runner_result) }
      assert_match(/BrokenEval#evaluate must return a score/, error.message)
    end

    test "a runner result stores without a prompt" do
      assert_nil @runner_result.prompt
      assert @runner_result.valid?
    end
  end
end
