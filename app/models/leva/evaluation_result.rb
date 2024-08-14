# == Schema Information
#
# Table name: leva_evaluation_results
#
#  id                     :integer          not null, primary key
#  label                  :string
#  prediction             :string
#  score                  :float
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  leva_dataset_record_id :integer          not null
#  leva_experiment_id     :integer          not null
#
# Indexes
#
#  index_leva_evaluation_results_on_leva_dataset_record_id  (leva_dataset_record_id)
#  index_leva_evaluation_results_on_leva_experiment_id      (leva_experiment_id)
#
# Foreign Keys
#
#  leva_dataset_record_id  (leva_dataset_record_id => leva_dataset_records.id)
#  leva_experiment_id      (leva_experiment_id => leva_experiments.id)
#
module Leva
  class EvaluationResult < ApplicationRecord
    belongs_to :experiment
    belongs_to :dataset_record

    delegate :record, to: :dataset_record, allow_nil: true
  end
end
