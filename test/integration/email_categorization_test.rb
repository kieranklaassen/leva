# frozen_string_literal: true

require "test_helper"

# End-to-end test for email categorization using DSPy.
# Requires ANTHROPIC_API_KEY environment variable to be set.
#
# Run with: ANTHROPIC_API_KEY=your_key bundle exec rails test test/integration/email_categorization_test.rb
module Leva
  class EmailCategorizationTest < ActiveSupport::TestCase
    include VcrTestHelper

    setup do
      skip "ANTHROPIC_API_KEY not set" unless ENV["ANTHROPIC_API_KEY"]

      DSPy.configure do |config|
        config.lm = DSPy::LM.new("ruby_llm/claude-3-5-haiku-latest")
      end

      @dataset = Dataset.create!(name: "Email Categorization Test")
      create_email_examples
    end

    test "categorizes emails correctly" do
      optimizer = PromptOptimizer.new(dataset: @dataset, mode: :light)

      assert optimizer.can_optimize?, "Dataset should have enough records"

      puts "\n=== Email Categorization Test ==="
      puts "Dataset: #{@dataset.name}"
      puts "Records: #{@dataset.dataset_records.count}"

      result = optimizer.optimize

      puts "Score: #{result[:metadata][:optimization][:score]}"
      puts "System Prompt: #{result[:system_prompt]}"

      # We expect high accuracy on this straightforward task
      score = result[:metadata][:optimization][:score]
      assert score >= 0.8, "Expected accuracy >= 80%, got #{(score * 100).round(1)}%"

      # Create the prompt
      prompt = Prompt.create!(
        name: "Email Categorizer",
        system_prompt: result[:system_prompt],
        user_prompt: result[:user_prompt],
        metadata: result[:metadata]
      )

      assert prompt.persisted?
      puts "Created prompt: #{prompt.name}"
    end

    private

    def create_email_examples
      emails = [
        # Support
        {
          subject: "Can't login to my account",
          body: "Hi, I've been trying to login but keep getting an error. Please help!",
          category: "support"
        },
        {
          subject: "Website is down",
          body: "Your website isn't loading for me. Is there an outage?",
          category: "support"
        },
        {
          subject: "How do I reset my password?",
          body: "I forgot my password and need to reset it. What are the steps?",
          category: "support"
        },
        {
          subject: "Bug report: checkout not working",
          body: "When I try to checkout, the page just refreshes. Nothing happens.",
          category: "support"
        },

        # Sales
        {
          subject: "Interested in your product",
          body: "Hi, I'd like to learn more about pricing for enterprise plans.",
          category: "sales"
        },
        {
          subject: "Request for proposal",
          body: "We're evaluating vendors and would like a quote for 50 licenses.",
          category: "sales"
        },
        {
          subject: "Demo request",
          body: "Can we schedule a demo of your platform next week?",
          category: "sales"
        },
        {
          subject: "Pricing question",
          body: "What's the difference between the Pro and Enterprise plans?",
          category: "sales"
        },

        # Feedback
        {
          subject: "Love your product!",
          body: "Just wanted to say your app has been amazing for our team.",
          category: "feedback"
        },
        {
          subject: "Feature suggestion",
          body: "It would be great if you added dark mode to the mobile app.",
          category: "feedback"
        },
        {
          subject: "Great customer service",
          body: "Sarah from your team was incredibly helpful. Thank you!",
          category: "feedback"
        },

        # Spam
        {
          subject: "YOU WON $1,000,000!!!",
          body: "Congratulations! Click here to claim your prize money now!",
          category: "spam"
        },
        {
          subject: "Free SEO services",
          body: "We noticed your website could rank higher. Get free consultation!",
          category: "spam"
        },
        {
          subject: "Urgent: Wire transfer needed",
          body: "I'm stranded overseas and need you to wire $5000 immediately.",
          category: "spam"
        }
      ]

      emails.each do |email|
        content = EmailContent.create!(
          subject: email[:subject],
          body: email[:body],
          category: email[:category]
        )
        @dataset.add_record(content)
      end
    end
  end
end
