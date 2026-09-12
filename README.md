# Leva - Flexible Evaluation Framework for Language Models

[![Gem Version](https://badge.fury.io/rb/leva.svg)](https://badge.fury.io/rb/leva)
[![CI](https://github.com/kieranklaassen/leva/actions/workflows/ci.yml/badge.svg)](https://github.com/kieranklaassen/leva/actions/workflows/ci.yml)

Leva is a Ruby on Rails framework for evaluating Language Models (LLMs) using ActiveRecord datasets on production models. It provides a flexible structure for creating experiments, managing datasets, and implementing various evaluation logic on production data with security in mind.

![✳ Mac Battery Drain- Warp@2x](https://github.com/user-attachments/assets/6c2ea720-a5ab-4ec4-9272-ee50114fa9f6)

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

Mount the Leva engine in your application's routes file:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount Leva::Engine => "/leva"
  # your other routes...
end
```

The Leva UI will then be available at `/leva` in your application.

To put your own authentication and authorization in front of the UI, name the
host controller Leva's controllers should inherit from (its `before_action`s,
helpers and error handling then apply to every Leva page):

```ruby
# config/initializers/leva.rb
Leva.configure do |config|
  config.parent_controller = "Admin::BaseController"   # default: "ActionController::Base"
end
```

## Usage

### 1. Setting up Datasets

First, create a dataset and add any ActiveRecord records you want to evaluate against. To make your models compatible with Leva, include the `Leva::Recordable` concern in your model:

```ruby
class TextContent < ApplicationRecord
  include Leva::Recordable

  # @return [String] The ground truth label for the record
  def ground_truth
    expected_label
  end

  # @return [Hash] A hash of attributes to be displayed in the dataset records index
  def index_attributes
    {
      text: text,
      expected_label: expected_label,
      created_at: created_at.strftime('%Y-%m-%d %H:%M:%S')
    }
  end

  # @return [Hash] A hash of attributes to be displayed in the dataset record show view
  def show_attributes
    {
      text: text,
      expected_label: expected_label,
      created_at: created_at.strftime('%Y-%m-%d %H:%M:%S')
    }
  end

  # @return [Hash] A hash of attributes to be displayed in the dataset record show view
  def to_llm_context
    {
      text: text,
      expected_label: expected_label,
      created_at: created_at.strftime('%Y-%m-%d %H:%M:%S')
    }
  end

  # Optional: Override for DSPy optimization (falls back to to_llm_context if not defined).
  # Use this to provide a simplified context with only the fields needed for optimization.
  # All values must be strings (nil values are automatically converted to empty strings).
  # @return [Hash<Symbol, String>] Context hash for DSPy optimization
  def to_dspy_context
    { text: text }
  end
end

dataset = Leva::Dataset.create(name: "Sentiment Analysis Dataset")
dataset.add_record TextContent.create(text: "I love this product!", expected_label: "Positive")
dataset.add_record TextContent.create(text: "Terrible experience", expected_label: "Negative")
dataset.add_record TextContent.create(text: "It's ok", expected_label: "Neutral")
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
  # runner_result is the stored Leva::RunnerResult; its #prediction is the run's output.
  def evaluate(runner_result, record)
    prediction = runner_result.prediction.to_s.strip
    score = prediction == record.expected_label ? 1.0 : 0.0
    # An optional second element is stored as `details` and shown in the UI.
    [score, "predicted #{prediction}, expected #{record.expected_label}"]
  end
end

class SentimentF1Eval < Leva::BaseEval
  def evaluate(runner_result, record)
    # Calculate F1 score
    # ...
    { score: f1_score, details: { precision: precision, recall: recall } }   # details may be a Hash (stored as JSON)
  end
end

class RubricEval < Leva::BaseEval
  def evaluate(runner_result, record)
    return nil unless record.rubric?   # nil abstains: nothing is stored for this run
    # ...
  end
end
```

`evaluate` may return a score, `[score, details]`, `{score:, details:}`, or `nil` to abstain.

### 4. Running Experiments

You can run experiments with different runs and evals:

```ruby
experiment = Leva::Experiment.create!(
  name: "Sentiment Analysis",
  dataset: dataset,
  runner_class: "SentimentRun",
  evaluator_classes: ["SentimentAccuracyEval", "SentimentF1Eval"]
)

run = SentimentRun.new
evals = [SentimentAccuracyEval.new, SentimentF1Eval.new]

Leva.run_evaluation(experiment: experiment, run: run, evals: evals)
```

An experiment needs no `Leva::Prompt` when the runner owns its prompt (your
application's production prompt, a fixed pipeline): leave `prompt` unset and
`execute_and_store(experiment, dataset_record)` stores the result without one.

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
  prompt: prompt,
  runner_class: "SentimentRun",
  evaluator_classes: ["SentimentAccuracyEval", "SentimentF1Eval"]
)

run = SentimentRun.new
evals = [SentimentAccuracyEval.new, SentimentF1Eval.new]

Leva.run_evaluation(experiment: experiment, run: run, evals: evals)
```

### 6. Analyzing Results

After the experiments are complete, analyze the results:

```ruby
experiment.evaluation_results.group_by(&:evaluator_class).each do |evaluator_class, results|
  average_score = results.average(&:score)
  puts "#{evaluator_class.capitalize} Average Score: #{average_score}"
end
```

## Prompt Optimization (DSPy Integration)

Leva includes optional prompt optimization powered by [DSPy.rb](https://github.com/kieranklaassen/dspy.rb). This feature automatically finds optimal prompts and few-shot examples for your datasets.

**Requirements:**
- Ruby 3.3.0 or higher
- DSPy gem and optional optimizer gems

### Installation

Add the DSPy gems to your Gemfile:

```ruby
gem "dspy"           # Core DSPy functionality (required)
gem "dspy-ruby_llm"  # RubyLLM provider adapter (required)
gem "dspy-gepa"      # GEPA optimizer (optional, recommended)
gem "dspy-miprov2"   # MIPROv2 optimizer (optional)
```

You can use any DSPy provider adapter instead of `dspy-ruby_llm`, such as `dspy-openai` or `dspy-anthropic`.

### Available Optimizers

| Optimizer | Best For | Description |
|-----------|----------|-------------|
| **Bootstrap** | Quick iteration, small datasets | Fast selection of few-shot examples. No gem required. |
| **GEPA** | Maximum quality | State-of-the-art reflective prompt evolution. 10-14% better than MIPROv2. |
| **MIPROv2** | Large datasets (200+) | Bayesian optimization for instructions and examples. |

### Usage

```ruby
# Create an optimizer for your dataset
optimizer = Leva::PromptOptimizer.new(
  dataset: dataset,
  optimizer: :gepa,      # :bootstrap, :gepa, or :miprov2
  mode: :medium,         # :light, :medium, or :heavy
  model: "claude-opus-4-5"   # Any model supported by RubyLLM
)

# Run optimization
result = optimizer.optimize

# Result contains optimized prompts
result[:system_prompt]  # Optimized instruction
result[:user_prompt]    # Template with Liquid variables
result[:metadata]       # Score, examples, and optimization details
```

### Optimization Modes

| Mode | Duration | Use Case |
|------|----------|----------|
| `:light` | ~5 min | Quick experiments |
| `:medium` | ~15 min | Balanced quality/speed |
| `:heavy` | ~30 min | Production prompts |

## Fine-tuning a Model (Together AI)

Leva can fine-tune an open model (Qwen3 via [Together AI](https://together.ai)) on a
dataset's `(input, ground_truth)` pairs and **register the result so it shows up
everywhere Leva lists models** — runnable through the normal RubyLLM path by any
runner, no custom runner required.

### Setup

```bash
export TOGETHER_API_KEY=...        # required: your Together API key
export TOGETHER_API_BASE=...       # optional: overrides https://api.together.xyz/v1
```

Leva registers an OpenAI-compatible `together` provider with RubyLLM at boot, so a
fine-tuned model registered under that provider routes to Together while genuine
OpenAI models are untouched.

### Usage

From a dataset page, click **Fine-tune Model** (enabled once the dataset has at
least 10 records). Leva exports the train split to chat-format JSONL, starts a LoRA
fine-tune on Together, tracks it to completion, and registers the resulting model.
Once complete, select it in any experiment or the workbench to evaluate it.

### How registration persists

Registered fine-tuned models are stored in a small overlay file and re-hydrated
into RubyLLM's registry at boot and on dropdown refresh — Leva never rewrites
RubyLLM's bundled catalog. Configure where the overlay lives, and who may trigger a
fine-tune (it spends money on your Together key and uploads dataset rows to a third
party), in an initializer:

```ruby
# config/initializers/leva.rb
Leva.configure do |config|
  # Restrict who can start a fine-tune (default: everyone who can reach the engine)
  config.authorize_fine_tune = ->(controller) { controller.current_user&.admin? }

  # Where registered fine-tuned models persist (default: config/leva_fine_tuned_models.json)
  config.fine_tuned_models_path = Rails.root.join("storage", "leva_fine_tuned_models.json").to_s
end
```

> **Multi-process note:** the model dropdown is cached for 5 minutes and busted on
> registration. For a freshly fine-tuned model to appear promptly across web and job
> processes, use a shared cache store (e.g. Redis/Memcached), not a per-process
> memory store.

> **Data boundary:** training data (inputs and ground-truth outputs) is uploaded to
> Together. Ensure datasets you fine-tune on contain no unapproved sensitive data.

## Configuration

Ensure you set up any required API keys or other configurations in your Rails credentials or environment variables.

## Leva's Components

### Classes

- `Leva`: Handles the process of running experiments.
- `Leva::BaseRun`: Base class for run implementations.
- `Leva::BaseEval`: Base class for eval implementations.

### Models

- `Leva::Dataset`: Represents a collection of data to be evaluated.
- `Leva::DatasetRecord`: Represents individual records within a dataset.
- `Leva::Experiment`: Represents a single run of an evaluation on a dataset.
- `Leva::RunnerResult`: Stores the results of each run execution.
- `Leva::EvaluationResult`: Stores the results of each evaluation.
- `Leva::Prompt`: Represents a prompt for an LLM.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kieranklaassen/leva.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Roadmap

- [x] Parallelize evaluation
