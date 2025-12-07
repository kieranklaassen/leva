# frozen_string_literal: true

module Leva
  # Optimizes prompts using DSPy.rb optimizers.
  #
  # This service coordinates the optimization process, delegating
  # the actual optimization work to strategy classes.
  #
  # @example Optimize a prompt for a dataset
  #   optimizer = Leva::PromptOptimizer.new(dataset: dataset, mode: :medium)
  #   result = optimizer.optimize
  #   # => { system_prompt: "...", user_prompt: "...", metadata: {...} }
  #
  # @example With GEPA optimizer
  #   optimizer = Leva::PromptOptimizer.new(dataset: dataset, optimizer: :gepa, mode: :medium)
  #   result = optimizer.optimize
  class PromptOptimizer
    # Minimum number of examples required for optimization
    MINIMUM_EXAMPLES = 10

    # Available optimizers with their strategy classes
    OPTIMIZERS = {
      bootstrap: {
        name: "Bootstrap",
        strategy_class: Leva::Optimizers::Bootstrap,
        gem: nil,
        description: "Fast and simple. Automatically selects optimal few-shot examples from your dataset. " \
                     "Best for quick iteration and when you have limited data (10-50 examples). " \
                     "Does not modify instructions, only adds demonstrations."
      },
      gepa: {
        name: "GEPA",
        strategy_class: Leva::Optimizers::GepaOptimizer,
        gem: "dspy-gepa",
        description: "State-of-the-art optimizer using reflective prompt evolution. Uses LLM reflection " \
                     "to identify what works and propose improvements. Outperforms MIPROv2 by 10-14% " \
                     "while being more sample efficient. Best choice for maximum quality."
      },
      miprov2: {
        name: "MIPROv2",
        strategy_class: Leva::Optimizers::Miprov2Optimizer,
        gem: "dspy-miprov2",
        description: "Uses Bayesian optimization to search for optimal instructions and few-shot examples. " \
                     "Good for larger datasets (200+ examples). More computationally demanding but thorough. " \
                     "Can overfit on small datasets."
      }
    }.freeze

    # Default optimizer
    DEFAULT_OPTIMIZER = :bootstrap

    # Optimization modes with their approximate durations
    MODES = {
      light: { description: "Fast optimization (~5 min)", trials: 5 },
      medium: { description: "Balanced optimization (~15 min)", trials: 15 },
      heavy: { description: "Thorough optimization (~30 min)", trials: 30 }
    }.freeze

    # Default model if none specified (fast and cheap)
    DEFAULT_MODEL = "gemini-2.5-flash"

    # Returns available models from RubyLLM.
    # Results are cached for 5 minutes to avoid repeated expensive calls.
    #
    # @return [Array<RubyLLM::Model>] All available chat models
    def self.available_models
      Rails.cache.fetch("leva/available_models", expires_in: 5.minutes) do
        RubyLLM.models.chat_models
      end
    end

    # Finds a model by ID.
    #
    # @param model_id [String] The model ID to find
    # @return [RubyLLM::Model, nil] The model or nil if not found
    def self.find_model(model_id)
      RubyLLM.models.find(model_id)
    rescue RubyLLM::ModelNotFoundError
      nil
    end

    # @return [Leva::Dataset] The dataset being optimized
    attr_reader :dataset

    # @return [Symbol] The optimization mode (:light, :medium, :heavy)
    attr_reader :mode

    # @return [String] The model to use for optimization
    attr_reader :model

    # @return [Symbol] The optimizer to use (:bootstrap, :gepa, :miprov2)
    attr_reader :optimizer

    # @param dataset [Leva::Dataset] The dataset to optimize for
    # @param metric [Proc, nil] Custom evaluation metric (default: exact string match)
    # @param mode [Symbol] Optimization intensity (:light, :medium, :heavy)
    # @param model [String, nil] The model to use (default: DEFAULT_MODEL)
    # @param optimizer [Symbol, String] The optimizer to use (default: :bootstrap)
    # @param progress_callback [Proc, nil] Callback for progress updates
    def initialize(dataset:, metric: nil, mode: :light, model: nil, optimizer: nil, progress_callback: nil)
      @dataset = dataset
      @metric = metric || default_metric
      @mode = mode.to_sym
      @model = model.presence || DEFAULT_MODEL
      @optimizer = (optimizer.presence || DEFAULT_OPTIMIZER).to_sym
      @progress_callback = progress_callback
      @last_progress = nil
    end

    # Runs the optimization process.
    #
    # @return [Hash] Hash containing :system_prompt, :user_prompt, and :metadata
    # @raise [Leva::InsufficientDataError] If dataset has too few records
    # @raise [Leva::DspyConfigurationError] If DSPy is not configured
    def optimize
      report_progress(step: "validating", progress: 0)
      validate_dataset!
      validate_dspy_configuration!
      validate_optimizer!

      report_progress(step: "splitting_data", progress: 10)
      splits = DatasetConverter.new(@dataset).split

      report_progress(step: "generating_signature", progress: 20)
      signature = SignatureGenerator.new(@dataset).generate

      # Delegate to optimizer strategy
      strategy = build_optimizer_strategy
      result = strategy.optimize(splits, signature)

      report_progress(step: "complete", progress: 100)

      build_final_result(result, splits, strategy.optimizer_type)
    end

    # Checks if the dataset is ready for optimization.
    #
    # @return [Boolean] True if the dataset can be optimized
    def can_optimize?
      @dataset.dataset_records.count >= MINIMUM_EXAMPLES
    end

    # Returns the number of additional records needed for optimization.
    #
    # @return [Integer] Number of records still needed (0 if ready)
    def records_needed
      [ MINIMUM_EXAMPLES - @dataset.dataset_records.count, 0 ].max
    end

    # Checks if a specific optimizer is available.
    #
    # @param optimizer_type [Symbol] The optimizer to check
    # @return [Boolean] True if the optimizer is available
    def self.optimizer_available?(optimizer_type)
      optimizer_type = optimizer_type.to_sym
      return true if optimizer_type == :bootstrap

      case optimizer_type
      when :gepa
        !!defined?(DSPy::Teleprompt::GEPA)
      when :miprov2
        !!defined?(DSPy::Teleprompt::MIPROv2)
      else
        false
      end
    end

    private

    # Builds the optimizer strategy instance.
    #
    # @return [Leva::Optimizers::Base] The optimizer strategy
    def build_optimizer_strategy
      config = OPTIMIZERS[@optimizer]
      config[:strategy_class].new(
        model: @model,
        metric: @metric,
        mode: @mode,
        progress_callback: @progress_callback
      )
    end

    # Builds the final result hash from optimization.
    #
    # @param result [Hash] The optimizer result with :instruction, :few_shot_examples, :score
    # @param splits [Hash] The data splits
    # @param optimizer_type [Symbol] The optimizer that was used
    # @return [Hash] The formatted result
    def build_final_result(result, splits, optimizer_type)
      sample_record = @dataset.dataset_records.first&.recordable
      input_fields = sample_record&.to_llm_context&.keys || []

      formatted_examples = result[:few_shot_examples].map do |ex|
        { input: ex[:input], output: ex.dig(:expected, :output) }
      end

      {
        system_prompt: result[:instruction],
        user_prompt: build_user_prompt_template(input_fields),
        metadata: {
          optimization: {
            score: result[:score],
            mode: @mode.to_s,
            optimizer: optimizer_type.to_s,
            model: @model,
            few_shot_examples: formatted_examples,
            optimized_at: Time.current.iso8601,
            dataset_size: @dataset.dataset_records.count,
            train_size: splits[:train].size,
            val_size: splits[:val].size,
            test_size: splits[:test].size
          }
        }
      }
    end

    # Reports progress to the callback if provided.
    # Throttles updates to only report when progress changes by 5% or more.
    #
    # @param step [String] Current step name
    # @param progress [Integer] Progress percentage (0-100)
    # @param examples_processed [Integer, nil] Number of examples processed
    # @param total [Integer, nil] Total examples to process
    # @return [void]
    def report_progress(step:, progress:, examples_processed: nil, total: nil)
      return unless @progress_callback

      # Skip if progress hasn't changed by at least 5%
      return if @last_progress && (progress - @last_progress).abs < 5

      @last_progress = progress
      @progress_callback.call(
        step: step,
        progress: progress,
        examples_processed: examples_processed,
        total: total
      )
    end

    # Validates that the dataset has enough records.
    #
    # @raise [Leva::InsufficientDataError] If dataset has too few records
    def validate_dataset!
      count = @dataset.dataset_records.count
      return if count >= MINIMUM_EXAMPLES

      raise InsufficientDataError,
        "Dataset needs at least #{MINIMUM_EXAMPLES} records for optimization, has #{count}"
    end

    # Validates that DSPy is properly configured.
    #
    # @raise [Leva::DspyConfigurationError] If DSPy is not configured
    def validate_dspy_configuration!
      unless defined?(DSPy) && defined?(DSPy::Predict)
        raise DspyConfigurationError, "DSPy is not installed. Add 'dspy' gem to your Gemfile."
      end
    end

    # Validates that the selected optimizer is available.
    #
    # @raise [Leva::DspyConfigurationError] If optimizer is not available
    def validate_optimizer!
      return if @optimizer == :bootstrap
      return if self.class.optimizer_available?(@optimizer)

      gem_name = OPTIMIZERS.dig(@optimizer, :gem)
      raise DspyConfigurationError, <<~MSG.strip
        #{@optimizer.to_s.upcase} optimizer is not available. Install it:

          gem 'dspy'
          gem '#{gem_name}'

        Or set DSPY_WITH_#{@optimizer.to_s.upcase}=1 before requiring dspy.
      MSG
    end

    # Returns the default evaluation metric (case-insensitive exact match).
    # Handles both Hash examples and DSPy::Example objects.
    #
    # @return [Proc] The default metric function
    def default_metric
      lambda do |example, prediction|
        # Handle both Hash and DSPy::Example
        expected_output = if example.is_a?(Hash)
                            example.dig(:expected, :output)
        else
                            # DSPy::Example has expected_values method to get Hash
                            example.expected_values[:output]
        end
        expected = expected_output.to_s.strip.downcase
        actual = prediction.to_s.strip.downcase
        expected == actual ? 1.0 : 0.0
      end
    end

    # Builds the user prompt template with Liquid placeholders.
    #
    # @param input_fields [Array<Symbol>] The input field names
    # @return [String] The user prompt template
    def build_user_prompt_template(input_fields)
      input_fields.map { |field| "{{ #{field} }}" }.join("\n\n")
    end
  end
end
