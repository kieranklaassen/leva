# frozen_string_literal: true

module Leva
  module Optimizers
    # GEPA (Genetic-Pareto) optimization strategy.
    #
    # Uses reflective prompt evolution with genetic algorithms
    # and Pareto optimization for best quality results.
    #
    # Requires the dspy-gepa gem.
    class GepaOptimizer < Base
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

      def compile(predictor, train_examples, val_examples, signature)
        lm = create_lm
        predictor.config.lm = lm

        # Build config based on mode intensity
        gepa_config = case mode
        when :light
                        { max_metric_calls: 16, minibatch_size: 2 }
        when :medium
                        { max_metric_calls: 32, minibatch_size: 2 }
        when :heavy
                        { max_metric_calls: 64, minibatch_size: 4 }
        else
                        { max_metric_calls: 16, minibatch_size: 2 }
        end

        gepa = DSPy::Teleprompt::GEPA.new(
          metric: metric,
          reflection_lm: DSPy::ReflectionLM.new("ruby_llm/#{model}"),
          config: gepa_config
        )

        trainset = to_dspy_examples(train_examples, signature)
        valset = to_dspy_examples(val_examples, signature)

        report_progress(step: "gepa_compiling", progress: 50)

        result = gepa.compile(predictor, trainset: trainset, valset: valset)

        { optimized: result.optimized_program, few_shot_examples: [] }
      end
    end
  end
end
