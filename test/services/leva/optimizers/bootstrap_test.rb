# frozen_string_literal: true

require "test_helper"

module Leva
  module Optimizers
    class BootstrapTest < ActiveSupport::TestCase
      setup do
        @metric = ->(example, prediction) { 1.0 }
        @optimizer = Bootstrap.new(
          model: "ruby_llm/claude-sonnet-4-20250514",
          metric: @metric,
          mode: :light
        )
      end

      test "step_name returns bootstrapping" do
        assert_equal "bootstrapping", @optimizer.step_name
      end

      test "optimizer_name returns Bootstrap" do
        assert_equal "Bootstrap", @optimizer.optimizer_name
      end

      test "optimizer_type returns :bootstrap" do
        assert_equal :bootstrap, @optimizer.optimizer_type
      end

      test "MODES defines light, medium, and heavy with trials" do
        assert_equal({ trials: 5 }, Bootstrap::MODES[:light])
        assert_equal({ trials: 15 }, Bootstrap::MODES[:medium])
        assert_equal({ trials: 30 }, Bootstrap::MODES[:heavy])
      end

      test "generate_optimized_instruction returns signature description for empty examples" do
        signature = Class.new do
          def self.description
            "Test description"
          end
        end

        result = @optimizer.send(:generate_optimized_instruction, [], signature)
        assert_equal "Test description", result
      end

      test "generate_optimized_instruction adds class labels for classification tasks" do
        signature = Class.new do
          def self.description
            "Classify the input"
          end
        end

        examples = [
          { expected: { output: "positive" } },
          { expected: { output: "negative" } },
          { expected: { output: "neutral" } }
        ]

        result = @optimizer.send(:generate_optimized_instruction, examples, signature)

        assert_includes result, "Classify the input"
        assert_includes result, "Respond with one of:"
        assert_includes result, "positive"
        assert_includes result, "negative"
        assert_includes result, "neutral"
      end

      test "generate_optimized_instruction uses signature description for non-classification tasks" do
        signature = Class.new do
          def self.description
            "Generate creative text"
          end
        end

        # More than 5 unique outputs = not classification
        examples = (1..10).map { |i| { expected: { output: "unique_output_#{i}" } } }

        result = @optimizer.send(:generate_optimized_instruction, examples, signature)
        assert_equal "Generate creative text", result
      end

      test "compile returns expected structure" do
        skip "Integration test - requires ANTHROPIC_API_KEY"
      end

      test "initializes with different modes" do
        %i[light medium heavy].each do |mode|
          optimizer = Bootstrap.new(
            model: "ruby_llm/claude-sonnet-4-20250514",
            metric: @metric,
            mode: mode
          )
          assert_equal mode, optimizer.mode
        end
      end

      test "inherits from Base" do
        assert_kind_of Base, @optimizer
      end
    end
  end
end
