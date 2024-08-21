# == Schema Information
#
# Table name: leva_runner_results
#
#  id                :integer          not null, primary key
#  actual_result     :text
#  prediction        :text
#  prompt_version    :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  dataset_record_id :integer          not null
#  experiment_id     :integer
#  prompt_id         :integer          not null
#
# Indexes
#
#  index_leva_runner_results_on_dataset_record_id  (dataset_record_id)
#  index_leva_runner_results_on_experiment_id      (experiment_id)
#  index_leva_runner_results_on_prompt_id          (prompt_id)
#
# Foreign Keys
#
#  dataset_record_id  (dataset_record_id => leva_dataset_records.id)
#  experiment_id      (experiment_id => leva_experiments.id)
#  prompt_id          (prompt_id => leva_prompts.id)
#
module Leva
  class RunnerResult < ApplicationRecord
    belongs_to :experiment, optional: true
    belongs_to :dataset_record
    belongs_to :prompt
    has_many :evaluation_results, dependent: :destroy

    validates :prediction, presence: true
    validates :actual_result, presence: true
    validates :prompt, presence: true
  end
end
