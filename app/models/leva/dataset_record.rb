# == Schema Information
#
# Table name: leva_dataset_records
#
#  id              :integer          not null, primary key
#  recordable_type :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  dataset_id      :integer          not null
#  recordable_id   :integer          not null
#
# Indexes
#
#  index_leva_dataset_records_on_dataset_id  (dataset_id)
#  index_leva_dataset_records_on_recordable  (recordable_type,recordable_id)
#
# Foreign Keys
#
#  dataset_id  (dataset_id => leva_datasets.id)
#
module Leva
  class DatasetRecord < ApplicationRecord
    belongs_to :dataset
    belongs_to :recordable, polymorphic: true

    has_many :runner_results, dependent: :destroy
    has_many :evaluation_results, dependent: :destroy, through: :runner_results

    # @return [Hash] A hash of attributes to be displayed in the dataset records index
    def index_attributes
      if recordable.respond_to?(:index_attributes)
        recordable.index_attributes
      elsif recordable.respond_to?(:name)
        { name: recordable.name }
      else
        { to_s: recordable.to_s }
      end
    end

    # @return [Hash] A hash of attributes to be displayed in the dataset record show view
    def show_attributes
      if recordable.respond_to?(:show_attributes)
        recordable.show_attributes
      elsif recordable.respond_to?(:dataset_attributes)
        recordable.dataset_attributes
      else
        { to_s: recordable.to_s }
      end
    end

    # @return [String] A string representation of the record for display purposes
    def display_name
      if recordable.respond_to?(:name)
        recordable.name
      elsif recordable.respond_to?(:title)
        recordable.title
      elsif recordable.is_a?(TextContent)
        "TextContent: #{recordable.text.truncate(30)}"
      else
        "#{recordable_type} ##{recordable_id}"
      end
    end
  end
end