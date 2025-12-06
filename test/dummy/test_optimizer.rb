# frozen_string_literal: true

# Test optimizer with real API calls
puts "Creating test dataset..."
dataset = Leva::Dataset.create!(name: "Test Optimizer", description: "Testing optimizer")

# Create text contents with labels
15.times do |i|
  sentiment = %w[positive negative neutral][i % 3]
  text = case sentiment
  when "positive" then "This product is amazing and works great!"
  when "negative" then "Terrible quality, would not recommend."
  else "The product is okay, nothing special."
  end

  tc = TextContent.create!(text: text, expected_label: sentiment)
  dataset.add_record(tc)
end

puts "Created dataset with #{dataset.dataset_records.count} records"

# Test optimizer initialization
puts ""
puts "Testing PromptOptimizer..."
optimizer = Leva::PromptOptimizer.new(
  dataset: dataset,
  mode: :light,
  model: "gemini-2.5-flash"
)

puts "Can optimize: #{optimizer.can_optimize?}"
puts "Model: #{optimizer.model}"
puts "Mode: #{optimizer.mode}"

# Run the optimization
puts ""
puts "Running optimization (this will make API calls)..."
result = optimizer.optimize

puts ""
puts "=== OPTIMIZATION RESULT ==="
puts "System prompt: #{result[:system_prompt][0..200]}..."
puts "User prompt: #{result[:user_prompt]}"
puts "Score: #{result[:metadata][:optimization][:score]}"
puts "Few-shot examples: #{result[:metadata][:optimization][:few_shot_examples].count}"
puts ""
puts "SUCCESS - Optimizer working!"

# Cleanup
dataset.destroy
