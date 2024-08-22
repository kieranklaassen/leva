# frozen_string_literal: true

class SentimentF1Eval < Leva::BaseEval
  # @param prediction [String] The prediction to evaluate
  # @param text_content [TextContent] The text content to evaluate
  # @return [Float] The score of the evaluation
  def evaluate(prediction, text_content)
    sleep 3 # Simulating a time-consuming operation
    # This is a simplified F1 score calculation for demonstration purposes
    # In a real-world scenario, you'd want to implement a proper F1 score calculation
    prediction == text_content.ground_truth ? rand(0.8..1.0) : rand(0.0..0.2)
  end
end