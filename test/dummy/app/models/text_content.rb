# == Schema Information
#
# Table name: text_contents
#
#  id             :integer          not null, primary key
#  expected_label :string
#  text           :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class TextContent < ApplicationRecord
  # @return [Hash] A hash of attributes to be displayed in the dataset partial
  def dataset_attributes
    {
      text: text,
      expected_label: expected_label,
      created_at: created_at.strftime('%Y-%m-%d %H:%M:%S')
    }
  end
end