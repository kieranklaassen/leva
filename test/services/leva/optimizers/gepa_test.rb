# frozen_string_literal: true

require "test_helper"

module Leva
  module Optimizers
    class GepaOptimizerTest < ActiveSupport::TestCase
      setup do
        @metric = ->(example, prediction) { 1.0 }
        @optimizer = Leva::Optimizers::GepaOptimizer.new(
          model: "gemini-2.5-flash",
          metric: @metric,
          mode: :light
        )
      end

      test "step_name returns gepa_optimizing" do
        assert_equal "gepa_optimizing", @optimizer.step_name
      end

      test "optimizer_name returns GEPA" do
        assert_equal "GEPA", @optimizer.optimizer_name
      end

      test "optimizer_type returns :gepa" do
        assert_equal :gepa, @optimizer.optimizer_type
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
          optimizer = Leva::Optimizers::GepaOptimizer.new(
            model: "gemini-2.5-flash",
            metric: @metric,
            mode: mode
          )
          assert_equal mode, optimizer.mode
        end
      end
    end

    class GepaAvailabilityTest < ActiveSupport::TestCase
      test "DSPy::Teleprompt::GEPA class exists" do
        assert defined?(DSPy::Teleprompt::GEPA)
      end

      test "PromptOptimizer.optimizer_available? returns true for GEPA" do
        assert Leva::PromptOptimizer.optimizer_available?(:gepa)
      end
    end
  end
end
