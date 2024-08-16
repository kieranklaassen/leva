class SentimentAccuracyEval < Leva::BaseEval
  def evaluate(prediction, record)
    prediction == record.expected_label ? 1.0 : 0.0
  end
end