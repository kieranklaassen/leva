# == Schema Information
#
# Table name: leva_experiments
#
#  id                :integer          not null, primary key
#  description       :text
#  evaluator_classes :text
#  metadata          :text
#  name              :string
#  runner_class      :string
#  status            :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  dataset_id        :integer          not null
#  prompt_id         :integer
#
# Indexes
#
#  index_leva_experiments_on_dataset_id  (dataset_id)
#  index_leva_experiments_on_prompt_id   (prompt_id)
#
# Foreign Keys
#
#  dataset_id  (dataset_id => leva_datasets.id)
#  prompt_id   (prompt_id => leva_prompts.id)
#
module Leva
  class Experiment < ApplicationRecord
    belongs_to :dataset
    belongs_to :prompt, optional: true
    has_many :runner_results, dependent: :destroy
    has_many :evaluation_results, through: :runner_results

    validates :name, presence: true
    validates :dataset, presence: true
    validates :runner_class, presence: true
    validates :evaluator_classes, presence: true

    enum :status, { pending: 0, running: 1, completed: 2, failed: 3 }, default: :pending

    serialize :evaluator_classes, coder: JSON, type: Array
  end
end