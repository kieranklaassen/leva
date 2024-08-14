# == Schema Information
#
# Table name: leva_dataset_records
#
#  id              :integer          not null, primary key
#  recordable_type :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  leva_dataset_id :integer          not null
#  recordable_id   :integer          not null
#
# Indexes
#
#  index_leva_dataset_records_on_leva_dataset_id  (leva_dataset_id)
#  index_leva_dataset_records_on_recordable       (recordable_type,recordable_id)
#
# Foreign Keys
#
#  leva_dataset_id  (leva_dataset_id => leva_datasets.id)
#
require "test_helper"

module Leva
  class DatasetRecordTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end
