# frozen_string_literal: true

module Leva
  module Optimizers
    # GEPA (Genetic-Pareto) optimization strategy.
    #
    # Uses reflective prompt evolution with genetic algorithms
    # and Pareto optimization for best quality results.
    #
    # Requires the dspy-gepa gem.
    class GEPA < Base
      def step_name
        "gepa_optimizing"
      end

      def optimizer_name
        "GEPA"
      end

      def optimizer_type
        :gepa
      end

      protected

      def compile(predictor, train_examples, val_examples, _signature)
        lm = create_lm
        predictor.config.lm = lm

        gepa = DSPy::Teleprompt::GEPA.new(
          metric: metric,
          reflection_lm: lm,
          auto: mode.to_s
        )

        trainset = to_dspy_examples(train_examples)
        valset = to_dspy_examples(val_examples)

        report_progress(step: "gepa_compiling", progress: 50)

        optimized = gepa.compile(student: predictor, trainset: trainset, valset: valset)

        { optimized: optimized, few_shot_examples: [] }
      end
    end
  end
end
