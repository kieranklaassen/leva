# frozen_string_literal: true

require "test_helper"

module Leva
  module Optimizers
    class Miprov2OptimizerTest < ActiveSupport::TestCase
      setup do
        @metric = ->(example, prediction) { 1.0 }
        @optimizer = Leva::Optimizers::Miprov2Optimizer.new(
          model: "gemini-2.5-flash",
          metric: @metric,
          mode: :light
        )
      end

      test "step_name returns miprov2_optimizing" do
        assert_equal "miprov2_optimizing", @optimizer.step_name
      end

      test "optimizer_name returns MIPROv2" do
        assert_equal "MIPROv2", @optimizer.optimizer_name
      end

      test "optimizer_type returns :miprov2" do
        assert_equal :miprov2, @optimizer.optimizer_type
      end

      test "inherits from Base" do
        assert_kind_of Leva::Optimizers::Base, @optimizer
      end

      test "initializes with required attributes" do
        assert_equal "gemini-2.5-flash", @optimizer.model
        assert_equal @metric, @optimizer.metric
        assert_equal :light, @optimizer.mode
      end

      test "initializes with different modes" do
        %i[light medium heavy].each do |mode|
          optimizer = Leva::Optimizers::Miprov2Optimizer.new(
            model: "gemini-2.5-flash",
            metric: @metric,
            mode: mode
          )
          assert_equal mode, optimizer.mode
        end
      end
    end

    class Miprov2AvailabilityTest < ActiveSupport::TestCase
      test "DSPy::Teleprompt::MIPROv2 class exists" do
        assert defined?(DSPy::Teleprompt::MIPROv2)
      end

      test "PromptOptimizer.optimizer_available? returns true for MIPROv2" do
        assert Leva::PromptOptimizer.optimizer_available?(:miprov2)
      end
    end
  end
end
