# == Schema Information
#
# Table name: leva_runner_results
#
#  id                :integer          not null, primary key
#  prediction        :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  dataset_record_id :integer          not null
#  experiment_id     :integer
#
# Indexes
#
#  index_leva_runner_results_on_dataset_record_id  (dataset_record_id)
#  index_leva_runner_results_on_experiment_id      (experiment_id)
#
# Foreign Keys
#
#  dataset_record_id  (dataset_record_id => leva_dataset_records.id)
#  experiment_id      (experiment_id => leva_experiments.id)
#
require "test_helper"

module Leva
  class RunnerResultTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end
