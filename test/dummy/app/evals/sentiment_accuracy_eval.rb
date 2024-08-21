# frozen_string_literal: true

class SentimentAccuracyEval < Leva::BaseEval
  # @param prediction [String] The prediction to evaluate
  # @param record [TextContent] The record to evaluate
  # @return [Float] The score of the evaluation
  def evaluate(prediction, text_content)
    prediction == text_content.expected_label ? 1.0 : 0.0
    [1.0, text_content.expected_label]
  end
end