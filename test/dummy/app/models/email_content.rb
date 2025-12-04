# frozen_string_literal: true

class EmailContent < ApplicationRecord
  include Leva::Recordable

  # @return [String] The ground truth category for the email
  def ground_truth
    category
  end

  # @return [Hash] Input context for LLM - only the email content
  def to_llm_context
    {
      subject: subject,
      body: body
    }
  end

  # @return [Hash] Display attributes for index view
  def index_attributes
    {
      subject: subject.truncate(40),
      category: category
    }
  end

  # @return [Hash] Display attributes for show view
  def show_attributes
    {
      subject: subject,
      body: body,
      category: category
    }
  end
end
