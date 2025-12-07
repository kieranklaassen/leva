# frozen_string_literal: true

module Leva
  # Converts Leva datasets to DSPy example format.
  #
  # This service transforms DatasetRecord objects into DSPy::Example objects
  # suitable for use with DSPy optimizers and predictors.
  #
  # @example Convert a dataset to DSPy examples
  #   converter = Leva::DatasetConverter.new(dataset)
  #   examples = converter.to_dspy_examples
  #
  # @example Split dataset for training
  #   converter = Leva::DatasetConverter.new(dataset)
  #   splits = converter.split(train_ratio: 0.6, val_ratio: 0.2)
  #   # => { train: [...], val: [...], test: [...] }
  class DatasetConverter
    # @param dataset [Leva::Dataset] The dataset to convert
    def initialize(dataset)
      @dataset = dataset
    end

    # Converts all dataset records to DSPy example format.
    #
    # @return [Array<Hash>] Array of example hashes with :input and :expected keys
    def to_dspy_examples
      @dataset.dataset_records.includes(:recordable).map do |record|
        next unless record.recordable

        {
          input: record.recordable.to_llm_context,
          expected: { output: record.recordable.ground_truth }
        }
      end.compact
    end

    # Splits the dataset into train, validation, and test sets.
    #
    # @param train_ratio [Float] Proportion of data for training (default: 0.6)
    # @param val_ratio [Float] Proportion of data for validation (default: 0.2)
    # @param seed [Integer, nil] Random seed for reproducibility
    # @return [Hash] Hash with :train, :val, and :test arrays
    def split(train_ratio: 0.6, val_ratio: 0.2, seed: nil)
      examples = to_dspy_examples
      examples = seed ? examples.shuffle(random: Random.new(seed)) : examples.shuffle

      train_size = (examples.size * train_ratio).to_i
      val_size = (examples.size * val_ratio).to_i

      {
        train: examples[0...train_size],
        val: examples[train_size...(train_size + val_size)],
        test: examples[(train_size + val_size)..]
      }
    end

    # Returns the count of valid records in the dataset.
    #
    # @return [Integer] Number of records with valid recordable objects
    def valid_record_count
      to_dspy_examples.size
    end
  end
end
