# frozen_string_literal: true

class SentimentAccuracyEval < Leva::BaseEval
  # @param runner_result [RunnerResult] The runner result to evaluate
  # @param text_content [TextContent] The text content to evaluate
  # @return [Float] The score of the evaluation
  def evaluate(runner_result, text_content)
    runner_result.parsed_predictions.first == text_content.ground_truth ? 1.0 : 0.0
  end
end