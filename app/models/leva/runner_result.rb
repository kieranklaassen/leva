# == Schema Information
#
# Table name: leva_runner_results
#
#  id                :integer          not null, primary key
#  prediction        :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  dataset_record_id :integer          not null
#  experiment_id     :integer          not null
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
module Leva
  class RunnerResult < ApplicationRecord
    belongs_to :experiment
    belongs_to :dataset_record
    has_many :evaluation_results, dependent: :destroy

    validates :prediction, presence: true
  end
end