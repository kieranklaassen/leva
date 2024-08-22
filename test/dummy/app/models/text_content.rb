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
  include Leva::Recordable

  # @return [String] The ground truth label for the record
  def ground_truth
    expected_label
  end

  # @return [Hash] A hash of attributes to be displayed in the dataset records index
  def index_attributes
    {
      text: text.truncate(50),
      expected_label: expected_label
    }
  end

  # @return [Hash] A hash of attributes to be displayed in the dataset record show view
  def show_attributes
    {
      text: text,
      expected_label: expected_label,
      created_at: created_at.strftime('%Y-%m-%d %H:%M:%S'),
      updated_at: updated_at.strftime('%Y-%m-%d %H:%M:%S')
    }
  end

  def to_llm_context
    {
      text: text,
      expected_label: expected_label
    }
  end
end