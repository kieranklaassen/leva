# frozen_string_literal: true

# Configure DSPy for prompt optimization
if defined?(DSPy)
  DSPy.configure do |config|
    config.lm = DSPy::LM.new(
      "anthropic/claude-sonnet-4-20250514",
      api_key: ENV["ANTHROPIC_API_KEY"]
    )
  end
end
