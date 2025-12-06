# frozen_string_literal: true

# Create a dataset for email categorization
dataset = Leva::Dataset.find_or_create_by!(name: "Email Categorization Demo")

# Clear existing records
dataset.dataset_records.destroy_all

# Add sample emails
emails = [
  { subject: "Cant login to my account", body: "Hi, I have been trying to login but keep getting an error. Please help!", category: "support" },
  { subject: "Website is down", body: "Your website is not loading for me. Is there an outage?", category: "support" },
  { subject: "How do I reset my password?", body: "I forgot my password and need to reset it. What are the steps?", category: "support" },
  { subject: "Interested in your product", body: "Hi, I would like to learn more about pricing for enterprise plans.", category: "sales" },
  { subject: "Request for proposal", body: "We are evaluating vendors and would like a quote for 50 licenses.", category: "sales" },
  { subject: "Demo request", body: "Can we schedule a demo of your platform next week?", category: "sales" },
  { subject: "Love your product!", body: "Just wanted to say your app has been amazing for our team.", category: "feedback" },
  { subject: "Feature suggestion", body: "It would be great if you added dark mode to the mobile app.", category: "feedback" },
  { subject: "YOU WON 1000000!!!", body: "Congratulations! Click here to claim your prize money now!", category: "spam" },
  { subject: "Free SEO services", body: "We noticed your website could rank higher. Get free consultation!", category: "spam" }
]

emails.each do |email|
  content = EmailContent.create!(
    subject: email[:subject],
    body: email[:body],
    category: email[:category]
  )
  dataset.add_record(content)
end

puts "Created dataset with #{dataset.dataset_records.count} email records"
