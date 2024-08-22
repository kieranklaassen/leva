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
  include RecordableConcern

  def index_attributes
    {
      text: text.truncate(50),
      expected_label: expected_label
    }
  end

  def show_attributes
    {
      text: text,
      expected_label: expected_label,
      created_at: created_at.strftime('%Y-%m-%d %H:%M:%S'),
      updated_at: updated_at.strftime('%Y-%m-%d %H:%M:%S')
    }
  end

  def display_name
    if respond_to?(:name)
      name
    elsif respond_to?(:title)
      title
    else
      "#{self.class.name} ##{id}"
    end
  end

  def to_llm_context
    {
      text: text,
      expected_label: expected_label
    }
  end
end
