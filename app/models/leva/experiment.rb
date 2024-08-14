# == Schema Information
#
# Table name: leva_experiments
#
#  id              :integer          not null, primary key
#  metadata        :text
#  name            :string
#  status          :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  leva_dataset_id :integer          not null
#  leva_prompt_id  :integer
#
# Indexes
#
#  index_leva_experiments_on_leva_dataset_id  (leva_dataset_id)
#  index_leva_experiments_on_leva_prompt_id   (leva_prompt_id)
#
# Foreign Keys
#
#  leva_dataset_id  (leva_dataset_id => leva_datasets.id)
#  leva_prompt_id   (leva_prompt_id => leva_prompts.id)
#
module Leva
  class Experiment < ApplicationRecord
    belongs_to :dataset
    belongs_to :prompt, optional: true

    has_many :evaluation_results, dependent: :destroy
  end
end
