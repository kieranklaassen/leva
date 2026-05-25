# == Schema Information
#
# Table name: leva_datasets
#
#  id          :integer          not null, primary key
#  description :text
#  name        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
module Leva
  class Dataset < ApplicationRecord
    has_many :dataset_records, dependent: :destroy
    has_many :experiments, dependent: :destroy
    has_many :optimization_runs, dependent: :destroy
    has_many :fine_tune_runs, dependent: :destroy

    validates :name, presence: true

    # Adds a record to the dataset if it doesn't already exist
    #
    # @param record [ActiveRecord::Base] The record to be added to the dataset
    # @return [Leva::DatasetRecord, nil] The created dataset record or nil if it already exists
    def add_record(record)
      dataset_records.find_or_create_by(recordable: record) do |dr|
        dr.recordable = record
      end
    end
  end
end
