# == Schema Information
#
# Table name: leva_prompts
#
#  id            :integer          not null, primary key
#  metadata      :text
#  name          :string
#  system_prompt :text
#  user_prompt   :text
#  version       :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require "test_helper"

module Leva
  class PromptTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end
