# == Schema Information
#
# Table name: leva_experiments
#
#  id         :integer          not null, primary key
#  metadata   :text
#  name       :string
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  dataset_id :integer          not null
#  prompt_id  :integer          not null
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
    belongs_to :prompt
  end
end
