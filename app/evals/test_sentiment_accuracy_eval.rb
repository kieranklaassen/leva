class TestSentimentAccuracyEval < Leva::BaseEval
  def evaluate(prediction, expected)
    score = prediction == expected ? 1.0 : 0.0
    Leva::Result.new(label: 'sentiment_accuracy', score: score)
  end
end