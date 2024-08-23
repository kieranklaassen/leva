module Leva
  module Recordable
    extend ActiveSupport::Concern

    included do
      has_many :dataset_records, as: :recordable, class_name: 'Leva::DatasetRecord', dependent: :destroy
      has_many :datasets, through: :dataset_records, class_name: 'Leva::Dataset'
      has_many :runner_results, through: :dataset_records, class_name: 'Leva::RunnerResult'
      has_many :evaluation_results, through: :runner_results, class_name: 'Leva::EvaluationResult'
    end

    # @return [String] The ground truth label for the record
    def ground_truth
      raise NotImplementedError, "#{self.class} must implement #ground_truth"
    end

    # @return [Hash] A hash of attributes to be displayed in the dataset records index
    def index_attributes
      raise NotImplementedError, "#{self.class} must implement #index_attributes"
    end

    # @return [Hash] A hash of attributes to be displayed in the dataset record show view
    def show_attributes
      raise NotImplementedError, "#{self.class} must implement #show_attributes"
    end

    # @return [Hash] A hash of attributes to be liquified for LLM context
    def to_llm_context
      raise NotImplementedError, "#{self.class} must implement #to_llm_context"
    end

    # @return [Regexp] A regex pattern to extract the contents of a LLM response
    def extract_regex_pattern
      false
    end
  end
end