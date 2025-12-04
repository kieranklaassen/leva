source "https://rubygems.org"

# Specify your gem's dependencies in leva.gemspec.
gemspec

gem "puma"

gem "sqlite3"

gem "sprockets-rails"

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"

gem "annotaterb", require: false

# DSPy.rb for prompt optimization (development/testing)
# Using fork with ruby-llm adapter and miprov2 fix
git "https://github.com/kieranklaassen/dspy.rb.git", branch: "feat/ruby-llm-adapter" do
  gem "dspy"
  gem "dspy-ruby_llm"
  gem "dspy-gepa"
  gem "dspy-miprov2"
end

# Required by dspy for observability
gem "opentelemetry-sdk"

# RubyLLM unified LLM adapter (required by dspy-ruby_llm)
gem "ruby_llm"
