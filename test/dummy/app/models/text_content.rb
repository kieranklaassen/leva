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
end
