# == Schema Information
#
# Table name: leva_experiments
#
#  id          :integer          not null, primary key
#  description :text
#  metadata    :text
#  name        :string
#  status      :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  dataset_id  :integer          not null
#  prompt_id   :integer
#
# Indexes
#
#  index_leva_experiments_on_dataset_id  (dataset_id)
#  index_leva_experiments_on_prompt_id   (prompt_id)
#
# Foreign Keys
#
#  dataset_id  (dataset_id => leva_datasets.id)
#  prompt_id   (prompt_id => leva_prompts.id)
#
require "test_helper"

module Leva
  class ExperimentTest < ActiveSupport::TestCase
    def setup
      dataset = Leva::Dataset.create(name: "Sentiment Analysis Dataset")
      dataset.add_record TextContent.create(text: "I love this product!", expected_label: "Positive")
      dataset.add_record TextContent.create(text: "Terrible experience", expected_label: "Negative")
      dataset.add_record TextContent.create(text: "I's ok", expected_label: "Neutral")
      @experiment = Leva::Experiment.create!(name: "Sentiment Analysis", dataset: dataset)

      @run = SentimentRun.new
      @evals = [SentimentAccuracyEval.new, SentimentF1Eval.new]
    end

    test "run evaluation with two evals and one runner" do
      Leva.run_evaluation(experiment: @experiment, run: @run, evals: @evals)

      assert_equal 6, @experiment.evaluation_results.count, "Should have 6 evaluation results (1 run * 3 records * 2 evals)"

      accuracy_results = @experiment.evaluation_results.where(label: 'sentiment_accuracy')
      f1_results = @experiment.evaluation_results.where(label: 'sentiment_f1')

      assert_equal 3, accuracy_results.count, "Should have 3 accuracy results"
      assert_equal 3, f1_results.count, "Should have 3 F1 results"

      average_accuracy = accuracy_results.average(:score)
      average_f1 = f1_results.average(:score)

      assert_equal 1.0, average_accuracy
      assert average_f1 < 1.0
    end
  end
end
