# Leva - Flexible Evaluation Framework for Language Models

Leva is a Ruby on Rails framework for evaluating Language Models (LLMs) using ActiveRecord datasets on production models. It provides a flexible structure for creating experiments, managing datasets, and implementing various evaluation logic on production data with security in mind.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'leva'
```

And then execute:

```bash
bundle install
```

Add the migrations to your database:

```bash
rails leva:install:migrations
rails db:migrate
```

## Usage

### 1. Setting up Datasets

First, create a dataset and add any ActiveRecord records you want to evaluate against:

```ruby
dataset = Leva::Dataset.create(name: "Sentiment Analysis Dataset")
dataset.add_record TextContent.create(text: "I love this product!", expected_label: "Positive")
dataset.add_record TextContent.create(text: "Terrible experience", expected_label: "Negative")
dataset.add_record TextContent.create(text: "I's ok", expected_label: "Neutral")
```

### 2. Implementing Runs

Create a run class to handle the execution of your inference logic:

```bash
rails generate leva:runner sentiment
```

```ruby
class SentimentRun < Leva::BaseRun
  def execute(record)
    # Your model execution logic here
    # This could involve calling an API, running a local model, etc.
    # Return the model's output
  end
end
```

### 3. Implementing Evals

Create one or more eval classes to evaluate the model's output:

```bash
rails generate leva:eval sentiment_accuracy
```

```ruby
class SentimentAccuracyEval < Leva::BaseEval
  def evaluate(prediction, expected)
    score = prediction == expected ? 1.0 : 0.0
    Leva::Result.new(label: 'sentiment_accuracy', score: score)
  end
end

class SentimentF1Eval < Leva::BaseEval
  def evaluate(prediction, expected)
    # Calculate F1 score
    # ...
    Leva::Result.new(label: 'sentiment_f1', score: f1_score)
  end
end
```

### 4. Running Experiments

You can run experiments with different runs and evals:

```ruby
experiment = Leva::Experiment.create!(name: "Sentiment Analysis", dataset: dataset)

run = SentimentRun.new
evals = [SentimentAccuracyEval.new, SentimentF1Eval.new]

Leva.run_evaluation(experiment: experiment, run: run, evals: evals)
```

### 5. Using Prompts

You can also use prompts with your runs:

```ruby
prompt = Leva::Prompt.create!(
  name: "Sentiment Analysis",
  version: 1,
  system_prompt: "You are an expert at analyzing text and returning the sentiment.",
  user_prompt: "Please analyze the following text and return the sentiment as Positive, Negative, or Neutral.\n\n{{TEXT}}",
  metadata: { model: "gpt-4", temperature: 0.5 }
)

experiment = Leva::Experiment.create!(
  name: "Sentiment Analysis with LLM",
  dataset: dataset,
  prompt: prompt
)

run = SentimentRun.new
evals = [SentimentAccuracyEval.new, SentimentF1Eval.new]

Leva.run_evaluation(experiment: experiment, run: run, evals: evals)
```

### 6. Analyzing Results

After the experiments are complete, analyze the results:

```ruby
experiment.evaluation_results.group_by(&:label).each do |label, results|
  average_score = results.average(&:score)
  puts "#{label.capitalize} Average Score: #{average_score}"
end
```

## Configuration

Ensure you set up any required API keys or other configurations in your Rails credentials or environment variables.

## Leva's Components

### Classes

- `Leva`: Handles the process of running experiments.
- `Leva::BaseRun`: Base class for run implementations.
- `Leva::BaseEval`: Base class for eval implementations.
- `Leva::Result`: Represents the result of an evaluation.

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
