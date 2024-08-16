class TestSentimentAccuracyEval < Leva::BaseEval
  def evaluate(prediction, expected)
    prediction == expected ? 1.0 : 0.0
  end
end