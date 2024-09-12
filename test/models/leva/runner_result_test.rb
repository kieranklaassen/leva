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
require "test_helper"

module Leva
  class RunnerResultTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end
