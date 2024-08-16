class SentimentRun < Leva::BaseRun
  def execute(record)
    # Simple sentiment analysis logic
    text = record.text.downcase
    if text.include?("love") || text.include?("great")
      "Positive"
    elsif text.include?("terrible") || text.include?("bad")
      "Negative"
    else
      "Neutral"
    end
  end
end