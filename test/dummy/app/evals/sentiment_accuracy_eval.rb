# frozen_string_literal: true

class SentimentAccuracyEval < Leva::BaseEval
  # @param prediction [String] The prediction to evaluate
  # @param record [TextContent] The record to evaluate
  # @return [Leva::Result] The result of the evaluation
  def evaluate(prediction, text_content)
    score = prediction == text_content.expected_label ? 1.0 : 0.0

    Leva::Result.new(
      label: "sentiment_accuracy",
      score: score
    )
  end
end