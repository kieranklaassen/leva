# frozen_string_literal: true

module Leva
  # Generates DSPy signatures from Leva dataset records.
  #
  # This service analyzes the structure of dataset records and generates
  # a dynamic DSPy::Signature class that matches the input/output schema.
  #
  # @example Generate a signature from a dataset
  #   generator = Leva::SignatureGenerator.new(dataset)
  #   signature_class = generator.generate
  #   predictor = DSPy::Predict.new(signature_class)
  class SignatureGenerator
    # @param dataset [Leva::Dataset] The dataset to analyze
    # @param description [String, nil] Optional description for the signature
    def initialize(dataset, description: nil)
      @dataset = dataset
      @description = description
      @sample_record = dataset.dataset_records.first&.recordable
    end

    # Generates a DSPy::Signature class based on the dataset structure.
    #
    # @return [Class, nil] A dynamically generated DSPy::Signature subclass, or nil if no sample
    def generate
      return nil unless @sample_record

      input_fields = extract_input_fields
      output_type = infer_output_type(@sample_record.ground_truth)
      description = @description || generate_description

      build_signature_class(input_fields, output_type, description)
    end

    # Returns the input field names that will be used in the signature.
    #
    # @return [Array<Symbol>] Array of input field names
    def input_field_names
      return [] unless @sample_record

      extract_input_fields.keys
    end

    private

    # Extracts input fields from the sample record's LLM context.
    #
    # @return [Hash<Symbol, Class>] Map of field names to their inferred types
    def extract_input_fields
      context = @sample_record.to_llm_context
      context.transform_values { |value| infer_type(value) }
    end

    # Infers the Ruby type for a given value.
    #
    # @param value [Object] The value to analyze
    # @return [Class] The inferred type (String, Integer, Float, Array, or Hash)
    def infer_type(value)
      case value
      when String then String
      when Integer then Integer
      when Float then Float
      when Array then Array
      when Hash then Hash
      else String
      end
    end

    # Infers the output type from ground truth.
    #
    # @param ground_truth [Object] The ground truth value to analyze
    # @return [Symbol] The output type (:string, :array, or :hash)
    def infer_output_type(ground_truth)
      case ground_truth
      when String then :string
      when Array then :array
      when Hash then :hash
      else :string
      end
    end

    # Generates a description for the signature based on the dataset.
    #
    # @return [String] A descriptive string for the signature
    def generate_description
      "Task generated from Leva dataset: #{@dataset.name}"
    end

    # Builds the DSPy::Signature class dynamically.
    #
    # @param input_fields [Hash<Symbol, Class>] Input field definitions
    # @param output_type [Symbol] The output type
    # @param description [String] Description for the signature
    # @return [Class] The generated signature class
    def build_signature_class(input_fields, output_type, description)
      # We need to capture these in local variables for the class block
      captured_input_fields = input_fields
      captured_description = description

      Class.new do
        # We'll define methods dynamically since DSPy::Signature may not be loaded
        @input_fields = captured_input_fields
        @output_type = :string
        @description = captured_description

        class << self
          attr_reader :input_fields, :output_type, :description

          def input_schema
            @input_fields.transform_values { |_| String }
          end

          def output_schema
            { output: String }
          end
        end

        def self.to_s
          "LevaGeneratedSignature"
        end
      end
    end
  end
end
