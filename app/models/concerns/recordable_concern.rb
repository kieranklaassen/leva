module RecordableConcern
  extend ActiveSupport::Concern

  included do
    # Define any necessary associations or validations here
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

  # @return [String] A string representation of the record for display purposes
  def display_name
    if respond_to?(:name)
      name
    elsif respond_to?(:title)
      title
    else
      "#{self.class.name} ##{id}"
    end
  end
end
