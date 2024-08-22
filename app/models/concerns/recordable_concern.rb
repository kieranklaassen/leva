module RecordableConcern
  extend ActiveSupport::Concern

  included do
    # Define any necessary associations or validations here
  end

  # @return [Hash] A hash of attributes to be displayed in the dataset records index
  def index_attributes
    raise NotImplementedError, "index_attributes method must be implemented in the including class"
  end

  # @return [Hash] A hash of attributes to be displayed in the dataset record show view
  def show_attributes
    raise NotImplementedError, "show_attributes method must be implemented in the including class"
  end

  # @return [Hash] A hash of attributes to be used in LLM context
  def to_llm_context
    raise NotImplementedError, "to_llm_context method must be implemented in the including class"
  end
end
