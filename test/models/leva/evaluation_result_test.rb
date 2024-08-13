# == Schema Information
#
# Table name: leva_evaluation_results
#
#  id                :integer          not null, primary key
#  label             :string
#  prediction        :string
#  score             :float
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  dataset_record_id :integer          not null
#  experiment_id     :integer          not null
#
# Indexes
#
#  index_leva_evaluation_results_on_dataset_record_id  (dataset_record_id)
#  index_leva_evaluation_results_on_experiment_id      (experiment_id)
#
# Foreign Keys
#
#  dataset_record_id  (dataset_record_id => dataset_records.id)
#  experiment_id      (experiment_id => experiments.id)
#
require "test_helper"

module Leva
  class EvaluationResultTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end
