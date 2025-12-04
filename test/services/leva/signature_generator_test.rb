# frozen_string_literal: true

require "test_helper"

module Leva
  class SignatureGeneratorTest < ActiveSupport::TestCase
    setup do
      @dataset = Leva::Dataset.create!(name: "Test Dataset")

      @text_content = TextContent.create!(
        text: "Test text",
        expected_label: "positive"
      )
      @dataset.add_record(@text_content)

      @generator = SignatureGenerator.new(@dataset)
    end

    test "generate returns a class" do
      signature = @generator.generate

      assert_kind_of Class, signature
    end

    test "generate returns nil for empty dataset" do
      empty_dataset = Leva::Dataset.create!(name: "Empty Dataset")
      generator = SignatureGenerator.new(empty_dataset)

      assert_nil generator.generate
    end

    test "input_field_names returns field names from to_llm_context" do
      field_names = @generator.input_field_names

      assert_includes field_names, :text
    end

    test "generated signature is DSPy::Signature subclass" do
      signature = @generator.generate

      assert signature < DSPy::Signature, "Should be a DSPy::Signature subclass"
    end

    test "generated signature has description" do
      signature = @generator.generate

      assert_respond_to signature, :description
      assert_match(/Classify the input/, signature.description)
    end

    test "custom description is used" do
      generator = SignatureGenerator.new(@dataset, description: "Custom task")
      signature = generator.generate

      assert_equal "Custom task", signature.description
    end
  end
end
