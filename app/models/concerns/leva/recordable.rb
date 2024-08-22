module Leva
  module Recordable
    extend ActiveSupport::Concern

    included do
      has_many :dataset_records, as: :recordable, class_name: 'Leva::DatasetRecord', dependent: :destroy
    end

    # @return [Hash] A hash of attributes to be displayed in the dataset records index
    def index_attributes
      raise NotImplementedError, "#{self.class} must implement #index_attributes"
    end

    # @return [Hash] A hash of attributes to be displayed in the dataset record show view
    def show_attributes
      raise NotImplementedError, "#{self.class} must implement #show_attributes"
    end

    def to_llm_context
      raise NotImplementedError, "#{self.class} must implement #to_llm_context"
    end
  end
end