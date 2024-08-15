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

    validates :name, presence: true

    def add_record(record)
      dataset_records.create(recordable: record)
    end
  end
end
