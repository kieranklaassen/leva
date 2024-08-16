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

    # @return [Hash] A hash of attributes to be displayed in the dataset partial
    def display_attributes
      if recordable.respond_to?(:dataset_attributes)
        recordable.dataset_attributes
      elsif recordable.respond_to?(:name)
        { name: recordable.name }
      else
        { to_s: recordable.to_s }
      end
    end
  end
end