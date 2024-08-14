class TestSentimentRun < Leva::BaseRun
  def execute(record)
    # Simple sentiment analysis logic for testing
    case record.content.downcase
    when /love|great|excellent/
      "Positive"
    when /terrible|bad|awful/
      "Negative"
    else
      "Neutral"
    end
  end
end