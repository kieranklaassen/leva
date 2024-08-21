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
module Leva
  class Prompt < ApplicationRecord
    has_many :experiments

    validates :name, presence: true
    validates :system_prompt, presence: true
    validates :user_prompt, presence: true

    before_save :increment_version

    # @return [void]
    def increment_version
      self.version ||= 0
      self.version += 1
    end
  end
end