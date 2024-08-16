# == Schema Information
#
# Table name: leva_evaluation_results
#
#  id                :integer          not null, primary key
#  evaluator_class   :string           not null
#  score             :float
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  dataset_record_id :integer          not null
#  experiment_id     :integer          not null
#  runner_result_id  :integer          not null
#
# Indexes
#
#  index_leva_evaluation_results_on_dataset_record_id  (dataset_record_id)
#  index_leva_evaluation_results_on_experiment_id      (experiment_id)
#  index_leva_evaluation_results_on_runner_result_id   (runner_result_id)
#
# Foreign Keys
#
#  dataset_record_id  (dataset_record_id => leva_dataset_records.id)
#  experiment_id      (experiment_id => leva_experiments.id)
#  runner_result_id   (runner_result_id => leva_runner_results.id)
#
module Leva
  class EvaluationResult < ApplicationRecord
    belongs_to :runner_result
    belongs_to :experiment
    belongs_to :dataset_record

    validates :score, presence: true
    validates :evaluator_class, presence: true

    delegate :record, to: :dataset_record, allow_nil: true
  end
end