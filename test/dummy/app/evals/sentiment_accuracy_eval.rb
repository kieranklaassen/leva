# frozen_string_literal: true

class SentimentAccuracyEval < Leva::BaseEval
  # @param prediction [String] The prediction to evaluate
  # @param text_content [TextContent] The text content to evaluate
  # @return [Float] The score of the evaluation
  def evaluate(prediction, text_content)
    prediction == text_content.ground_truth ? 1.0 : 0.0
  end
end