require "test_helper"

class LevaTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert Leva::VERSION
  end

  test "default_model falls back to the optimizer's default" do
    assert_equal Leva::PromptOptimizer::DEFAULT_MODEL, Leva::Configuration.new.default_model
  end

  test "default_model accepts a model id or a callable read on each access" do
    config = Leva::Configuration.new
    config.default_model = "claude-sonnet-4-5"
    assert_equal "claude-sonnet-4-5", config.default_model

    current = "gpt-5"
    config.default_model = -> { current }
    assert_equal "gpt-5", config.default_model
    current = "gpt-5-mini"
    assert_equal "gpt-5-mini", config.default_model

    config.default_model = -> { nil }
    assert_equal Leva::PromptOptimizer::DEFAULT_MODEL, config.default_model
  end
end
