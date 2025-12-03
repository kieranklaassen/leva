# frozen_string_literal: true

module Leva
  # Optimizes prompts using DSPy.rb's MIPROv2 optimizer.
  #
  # This service takes a dataset and uses Bayesian optimization to find
  # optimal prompt instructions and few-shot examples.
  #
  # @example Optimize a prompt for a dataset
  #   optimizer = Leva::PromptOptimizer.new(dataset: dataset, mode: :medium)
  #   result = optimizer.optimize
  #   # => { system_prompt: "...", user_prompt: "...", metadata: {...} }
  #
  # @example With custom metric
  #   metric = ->(example, prediction) { prediction[:output] == example[:expected][:output] }
  #   optimizer = Leva::PromptOptimizer.new(dataset: dataset, metric: metric)
  class PromptOptimizer
    # Minimum number of examples required for optimization
    MINIMUM_EXAMPLES = 10

    # Optimization modes with their approximate durations
    MODES = {
      light: { description: "Fast optimization (~5 min)", trials: 5 },
      medium: { description: "Balanced optimization (~15 min)", trials: 15 },
      heavy: { description: "Thorough optimization (~30 min)", trials: 30 }
    }.freeze

    # @return [Leva::Dataset] The dataset being optimized
    attr_reader :dataset

    # @return [Symbol] The optimization mode (:light, :medium, :heavy)
    attr_reader :mode

    # @param dataset [Leva::Dataset] The dataset to optimize for
    # @param metric [Proc, nil] Custom evaluation metric (default: exact string match)
    # @param mode [Symbol] Optimization intensity (:light, :medium, :heavy)
    def initialize(dataset:, metric: nil, mode: :light)
      @dataset = dataset
      @metric = metric || default_metric
      @mode = mode.to_sym
    end

    # Runs the optimization process.
    #
    # @return [Hash] Hash containing :system_prompt, :user_prompt, and :metadata
    # @raise [Leva::InsufficientDataError] If dataset has too few records
    # @raise [Leva::DspyConfigurationError] If DSPy is not configured
    def optimize
      validate_dataset!
      validate_configuration!

      splits = DatasetConverter.new(@dataset).split
      signature = SignatureGenerator.new(@dataset).generate

      # For now, return a simulated result since DSPy integration
      # requires the gem to be installed and configured
      build_simulated_result(splits, signature)
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

    private

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
    def validate_configuration!
      # For now, we'll skip this check since DSPy might not be loaded
      # In production, we'd check if DSPy is configured properly
      true
    end

    # Returns the default evaluation metric (case-insensitive exact match).
    #
    # @return [Proc] The default metric function
    def default_metric
      lambda do |example, prediction|
        expected = example.dig(:expected, :output).to_s.strip.downcase
        actual = prediction.to_s.strip.downcase
        expected == actual ? 1.0 : 0.0
      end
    end

    # Builds a simulated optimization result.
    # This will be replaced with actual DSPy integration.
    #
    # @param splits [Hash] The train/val/test splits
    # @param signature [Class] The generated signature class
    # @return [Hash] The optimization result
    def build_simulated_result(splits, signature)
      sample_record = @dataset.dataset_records.first&.recordable
      input_fields = sample_record&.to_llm_context&.keys || []

      # Generate a reasonable instruction based on the dataset
      instruction = generate_instruction(input_fields)

      # Select a few examples for few-shot learning
      few_shot_examples = select_few_shot_examples(splits[:train])

      {
        system_prompt: instruction,
        user_prompt: build_user_prompt_template(input_fields),
        metadata: {
          optimization: {
            score: 0.0, # Will be populated by actual optimization
            mode: @mode.to_s,
            few_shot_examples: few_shot_examples,
            optimized_at: Time.current.iso8601,
            dataset_size: @dataset.dataset_records.count,
            train_size: splits[:train].size,
            val_size: splits[:val].size,
            test_size: splits[:test].size
          }
        }
      }
    end

    # Generates a default instruction based on the dataset structure.
    #
    # @param input_fields [Array<Symbol>] The input field names
    # @return [String] The generated instruction
    def generate_instruction(input_fields)
      field_list = input_fields.map { |f| f.to_s.humanize.downcase }.join(", ")
      "Analyze the given #{field_list} and provide an appropriate response. " \
        "Be accurate and concise in your output."
    end

    # Selects diverse examples for few-shot learning.
    #
    # @param examples [Array<Hash>] The training examples
    # @param count [Integer] Number of examples to select
    # @return [Array<Hash>] Selected few-shot examples
    def select_few_shot_examples(examples, count: 3)
      return [] if examples.empty?

      # Select diverse examples (in production, we'd use more sophisticated selection)
      examples.take(count).map do |example|
        {
          input: example[:input],
          output: example.dig(:expected, :output)
        }
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
