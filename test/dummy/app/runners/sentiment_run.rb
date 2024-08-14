# frozen_string_literal: true

class SentimentRun < Leva::BaseRun
  # Executes sentiment analysis on the given text content.
  #
  # @param text_content [TextContent] The text to analyze
  # @return [String] The sentiment analysis result (Positive, Neutral, or Negative)
  def execute(text_content)
    text = text_content.text.downcase

    case
    when text.match?(/\b(love|great|excellent|awesome|fantastic)\b/)
      "Positive"
    when text.match?(/\b(hate|terrible|awful|horrible|bad)\b/)
      "Negative"
    else
      "Neutral"
    end
  end
end