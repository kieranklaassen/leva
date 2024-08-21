# frozen_string_literal: true

class SentimentF1Eval < Leva::BaseEval
  # @param prediction [String] The prediction to evaluate
  # @param text_content [TextContent] The record to evaluate
  # @return [Float] The score of the evaluation
  def evaluate(prediction, text_content)
    sleep 3
    rand
  end
end