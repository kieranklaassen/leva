# frozen_string_literal: true

class SentimentRun < Leva::BaseRun
  # Executes sentiment analysis on the given text content.
  #
  # @param text_content [TextContent] The text to analyze
  # @return [String] The sentiment analysis result (Positive, Neutral, or Negative)
  def execute(text_content)
    text = text_content.text.downcase

    sentiment = case
    when text.match?(/\b(love|great|excellent|awesome|fantastic)\b/)
      "Positive"
    when text.match?(/\b(hate|terrible|awful|horrible|bad)\b/)
      "Negative"
    else
      "Neutral"
    end

    """
Wow, this is a great text!

<sentiment>#{sentiment}</sentiment>
    """
  end

  # Provides additional context specific to sentiment analysis.
  # This demonstrates an expensive operation that shouldn't be in
  # the record's general to_llm_context method.
  #
  # @param record [TextContent] The text content to analyze
  # @return [Hash] Additional context for the LLM prompt
  def to_llm_context(record)
    {
      # Example: Count similar texts (expensive database query)
      similar_texts_count: record.class.where(
        "text LIKE ?", "%#{record.text.split.first}%"
      ).count
    }
  end
end