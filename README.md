# Leva - Flexible Evaluation Framework for Language Models

Leva is a Ruby on Rails framework for evaluating Language Models (LLMs) using ActiveRecord datasets. It provides a flexible structure for creating experiments, managing datasets, and implementing various evaluation logic.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'leva'
```

And then execute:

```bash
$ bundle install
```

## Usage

### 1. Setting up Datasets

First, create a dataset and add any ActiveRecord records:

```ruby
dataset = Dataset.create(name: "Sentiment Analysis Dataset")

dataset.records << TextContent.create(text: "I love this product!", expected_label: "Positive")
dataset.records << TextContent.create(text: "Terrible experience", expected_label: "Negative")
dataset.records << TextContent.create(text: "I's ok", expected_label: "Neutral")
```

> In this case the TextContent model is the ActiveRecord model from your own application.

### 2. Implementing Evals

Create evals by adding new files in `app/evals/`. Each eval implements both the evaluation logic and how to run it. Here are some examples:

```bash
$ rails generate leva:eval Sentiment
```

#### Sentiment Evaluation (app/evals/sentiment_eval.rb)

```ruby
class SentimentEval < Leva::BaseEval
  leva_dataset_record_class "TextContent"

  def run_each(record)
    prediction = label_sentiment(record.text)
    score = calculate_score(prediction, record.expected_label)

    Leva::Result.new(
      label: 'sentiment',
      prediction: prediction,
      score: score
    )
  end

  private

  def label_sentiment(text)
    # Simple sentiment analysis logic, use LLM to label the sentiment yourself
    text = text.downcase
    if text.include?('love')
      'Positive'
    elsif text.include?('terrible')
      'Negative'
    else
      'Neutral'
    end
  end

  def calculate_score(prediction, expected)
    prediction == expected ? 1.0 : 0.0
  end
end
```

### 3. Running Experiments

You can run experiments with different evals:

```ruby
sentiment_experiment = Experiment.create!(name: "Sentiment Analysis", dataset: dataset)
SentimentEval.run_experiment(sentiment_experiment)
```

You can also run an experiment with a prompt so you can use a LLM to evaluate the dataset:

```ruby
prompt = Leva::Prompt.create!(
  name: "Sentiment Analysis",
  version: 1,
  system_prompt: "You are an expert at analyzing text and returning the sentiment.",
  user_prompt: "Please analyze the following text and return the sentiment as Positive, Negative, or Neutral.  \n\n {{TEXT}}",
  metadata: {
    model: "gpt-4o",
    temperature: 0.5
  }
)

sentiment_experiment = Experiment.create!(
  name: "Sentiment Analysis with LLM",
  dataset: dataset,
  prompt: prompt
)

SentimentEval.run_experiment(sentiment_experiment)
```

### 4. Analyzing Results

After the experiments are complete, analyze the results:

```ruby

results = experiment.evaluation_results
average_score = results.average(:score)
count = results.count

puts "Experiment: #{experiment.name}"
puts "Average Score: #{average_score}"
puts "Number of Evaluations: #{count}"
```

## Configuration

If your evals require API keys or other configurations, ensure you set these up in your Rails credentials or environment variables.

## Leva's Components

### Classes

- `Leva::BaseEval`: The base class for all evals. Override the `run` method in your eval classes.
- `Leva::Result`: The result of an evaluation.

### Models

- `Leva::Dataset`: Represents a collection of data to be evaluated.
- `Leva::DatasetRecord`: Represents individual records within a dataset.
- `Leva::Experiment`: Represents a single run of an evaluation on a dataset.
- `Leva::EvaluationResult`: Stores the results of each evaluation.
- `Leva::Prompt`: Represents a prompt for an LLM.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kieranklaassen/leva.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
