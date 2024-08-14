# frozen_string_literal: true

class SentimentF1Eval < Leva::BaseEval
  # @param prediction [String] The prediction to evaluate
  # @param text_content [TextContent] The record to evaluate
  # @return [Leva::Result] The result of the evaluation
  def evaluate(prediction, text_content)
    score = rand

    Leva::Result.new(
      label: "sentiment_f1",
      score: score
    )
  end
end