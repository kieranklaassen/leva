# == Schema Information
#
# Table name: leva_runner_results
#
#  id                :integer          not null, primary key
#  prediction        :text
#  prompt_version    :integer
#  runner_class      :string
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
    validates :prompt, presence: true
    validates :runner_class, presence: true

    delegate :ground_truth, to: :dataset_record

    # @return [Array<String>] The parsed draft responses
    def parsed_predictions
      @parsed_predictions ||= runner&.parsed_predictions(self) || []
    end

    # @return [String] The ground truth for this runner result
    def ground_truth
      @ground_truth ||= runner&.ground_truth(self)
    end

    private

    def runner
      @runner ||= runner_class&.constantize&.new
    end
  end
end
