# frozen_string_literal: true

# Seeds for the Leva dummy application
# Run with: cd test/dummy && bin/rails db:seed

puts "Creating seed data for Leva workbench..."

# Clear existing data
Leva::EvaluationResult.destroy_all
Leva::RunnerResult.destroy_all
Leva::Experiment.destroy_all
Leva::DatasetRecord.destroy_all
Leva::Dataset.destroy_all
Leva::Prompt.destroy_all
TextContent.destroy_all

# Create a dataset
dataset = Leva::Dataset.create!(
  name: "Product Review Sentiment Analysis",
  description: "A collection of product reviews for sentiment classification training and evaluation"
)
puts "Created dataset: #{dataset.name}"

# Create text content records with varied reviews
reviews = [
  {
    text: "This product exceeded all my expectations! The build quality is exceptional and it works exactly as advertised. I've been using it daily for two weeks now and couldn't be happier with my purchase. Highly recommend to anyone looking for a reliable solution.",
    expected_label: "Positive"
  },
  {
    text: "Absolutely terrible experience. The item arrived damaged and customer service was unhelpful. Spent three days trying to get a refund. Would not recommend to anyone. Complete waste of money.",
    expected_label: "Negative"
  },
  {
    text: "It's okay, nothing special. Does what it says but the quality could be better for the price. Average product overall.",
    expected_label: "Neutral"
  },
  {
    text: "Outstanding customer service and the product itself is top-notch. Fast shipping, great packaging, and the item works flawlessly. This company really cares about their customers.",
    expected_label: "Positive"
  },
  {
    text: "Don't buy this! Broke after just two uses. Cheaply made and overpriced. The reviews must be fake because this is garbage.",
    expected_label: "Negative"
  }
]

text_contents = reviews.map do |review|
  TextContent.create!(text: review[:text], expected_label: review[:expected_label])
end
puts "Created #{text_contents.count} text content records"

# Create dataset records
dataset_records = text_contents.map do |tc|
  Leva::DatasetRecord.create!(dataset: dataset, recordable: tc)
end
puts "Created #{dataset_records.count} dataset records"

# Create a prompt with detailed system and user prompts
prompt = Leva::Prompt.create!(
  name: "Sentiment Classifier v3",
  version: 12,
  system_prompt: <<~SYSTEM,
    You are an expert sentiment analysis model specialized in product reviews. Your task is to classify the sentiment of customer reviews into one of three categories: Positive, Negative, or Neutral.

    Guidelines for classification:
    - POSITIVE: Reviews expressing satisfaction, happiness, recommendation, or praise
    - NEGATIVE: Reviews expressing dissatisfaction, complaints, warnings, or criticism
    - NEUTRAL: Reviews that are balanced, factual, or express mixed feelings

    Always provide your answer in XML format with the sentiment wrapped in <sentiment> tags.
  SYSTEM
  user_prompt: <<~USER
    Please analyze the following product review and classify its sentiment:

    Review: {{ text }}

    Expected sentiment categories: Positive, Negative, or Neutral

    Provide your classification in this exact format:
    <sentiment>YOUR_CLASSIFICATION</sentiment>
  USER
)
puts "Created prompt: #{prompt.name} v#{prompt.version}"

# Create some runner results with varied outputs
predictions = [
  {
    record_index: 0,
    prediction: <<~PRED
      Based on my analysis of this product review, I can identify several strong positive indicators:

      1. The customer explicitly states their expectations were "exceeded"
      2. They praise the "build quality" as "exceptional"
      3. They confirm regular daily usage over two weeks
      4. They express high satisfaction with phrases like "couldn't be happier"
      5. They provide a recommendation to others

      All of these factors clearly indicate a positive sentiment.

      <sentiment>Positive</sentiment>
    PRED
  },
  {
    record_index: 1,
    prediction: <<~PRED
      Analyzing this review reveals multiple negative sentiment indicators:

      1. The phrase "Absolutely terrible experience" sets a strongly negative tone
      2. Product arrived damaged - a clear complaint
      3. Customer service described as "unhelpful"
      4. Time wasted (three days) trying to resolve issues
      5. Explicit anti-recommendation: "Would not recommend to anyone"
      6. Described as "Complete waste of money"

      The sentiment is clearly negative.

      <sentiment>Negative</sentiment>
    PRED
  },
  {
    record_index: 2,
    prediction: <<~PRED
      This review exhibits characteristics of neutral sentiment:

      1. "It's okay, nothing special" - lukewarm assessment
      2. Acknowledges functionality: "Does what it says"
      3. Mild criticism: "quality could be better for the price"
      4. Balanced conclusion: "Average product overall"

      Neither strongly positive nor negative - this is a neutral review.

      <sentiment>Neutral</sentiment>
    PRED
  }
]

predictions.each do |pred|
  Leva::RunnerResult.create!(
    dataset_record: dataset_records[pred[:record_index]],
    prompt: prompt,
    prompt_version: prompt.version,
    prediction: pred[:prediction],
    runner_class: "SentimentRun"
  )
end
puts "Created #{predictions.count} runner results"

puts "\nSeed data created successfully!"
puts "Visit http://localhost:3000/leva/workbench to see the workbench"
