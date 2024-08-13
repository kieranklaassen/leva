# == Schema Information
#
# Table name: leva_datasets
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module Leva
  class Dataset < ApplicationRecord
    has_many :dataset_records, dependent: :destroy
    has_many :records, through: :dataset_records, source: :recordable
    has_many :experiments, dependent: :destroy
  end
end
