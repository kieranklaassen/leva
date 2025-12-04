# frozen_string_literal: true

module Leva
  module Optimizers
    # MIPROv2 optimization strategy.
    #
    # Uses Bayesian optimization with Gaussian Processes
    # for efficient prompt search.
    #
    # Requires the dspy-miprov2 gem.
    class Miprov2Optimizer < Base
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

      def compile(predictor, train_examples, val_examples, signature)
        predictor.config.lm = create_lm

        # Use AutoMode helpers for preset configurations
        mipro = case mode
        when :light
                  DSPy::Teleprompt::MIPROv2::AutoMode.light(metric: metric)
        when :medium
                  DSPy::Teleprompt::MIPROv2::AutoMode.medium(metric: metric)
        when :heavy
                  DSPy::Teleprompt::MIPROv2::AutoMode.heavy(metric: metric)
        else
                  DSPy::Teleprompt::MIPROv2::AutoMode.light(metric: metric)
        end

        trainset = to_dspy_examples(train_examples, signature)
        valset = to_dspy_examples(val_examples, signature)

        report_progress(step: "miprov2_compiling", progress: 50)

        result = mipro.compile(predictor, trainset: trainset, valset: valset)

        { optimized: result.optimized_program, few_shot_examples: [] }
      end
    end
  end
end
