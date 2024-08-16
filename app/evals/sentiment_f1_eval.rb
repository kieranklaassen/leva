class SentimentF1Eval < Leva::BaseEval
  def evaluate(prediction, record)
    # Simplified F1 score calculation for demonstration
    expected = record.expected_label
    if prediction == expected
      1.0
    else
      0.5 # Simplified, non-zero score for incorrect predictions
    end
  end
end