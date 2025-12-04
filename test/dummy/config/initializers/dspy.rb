# frozen_string_literal: true

# Configure RubyLLM with API keys from environment
if defined?(RubyLLM)
  RubyLLM.configure do |config|
    config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
    config.openai_api_key = ENV["OPENAI_API_KEY"]
    config.gemini_api_key = ENV["GEMINI_API_KEY"]
  end
end

# Configure DSPy for prompt optimization (using ruby_llm adapter)
if defined?(DSPy)
  DSPy.configure do |config|
    config.lm = DSPy::LM.new("ruby_llm/gemini-2.5-flash")
  end
end
