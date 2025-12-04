# frozen_string_literal: true

module Leva
  module Optimizers
    # MIPROv2 optimization strategy.
    #
    # Uses Bayesian optimization with Gaussian Processes
    # for efficient prompt search.
    #
    # Requires the dspy-miprov2 gem.
    class MIPROv2 < Base
      def step_name
        "miprov2_optimizing"
      end

      def optimizer_name
        "MIPROv2"
      end

      def optimizer_type
        :miprov2
      end

      protected

      def compile(predictor, train_examples, val_examples, _signature)
        predictor.config.lm = create_lm

        mipro = DSPy::Teleprompt::MIPROv2.new(
          metric: metric,
          auto: mode.to_s
        )

        trainset = to_dspy_examples(train_examples)
        valset = to_dspy_examples(val_examples)

        report_progress(step: "miprov2_compiling", progress: 50)

        optimized = mipro.compile(student: predictor, trainset: trainset, valset: valset)

        { optimized: optimized, few_shot_examples: [] }
      end
    end
  end
end
