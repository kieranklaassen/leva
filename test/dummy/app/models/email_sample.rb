# frozen_string_literal: true

# A realistic email used as Leva training data for email categorization.
#
# `to_llm_context` exposes the fields a classifier sees (sender + subject +
# body); `ground_truth` is the Cora category slug. The STI subclass
# {EmailRoutingSample} extends the label with the inbox/briefed/archived routing.
#
# Seeded by `script/datasets/seed_category_dataset.rb`.
class EmailSample < ApplicationRecord
  include Leva::Recordable

  # @return [String] the Cora category slug (the label to predict)
  def ground_truth
    category
  end

  # @return [Hash] the classifier's view of the email
  def to_llm_context
    {
      from: from,
      from_name: from_name,
      subject: subject,
      body: body
    }
  end

  # @return [Hash] columns shown in the dataset records index
  def index_attributes
    {
      from: from,
      subject: subject,
      category: category
    }
  end

  # @return [Hash] columns shown in the dataset record show view
  def show_attributes
    {
      from: from,
      from_name: from_name,
      subject: subject,
      body: body,
      category: category,
      routing: routing
    }
  end
end
