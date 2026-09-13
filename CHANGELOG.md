# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- `Leva.config.parent_controller`: the host controller every Leva controller inherits from (default `ActionController::Base`), so a host's authentication and authorization before_actions gate the whole UI
- `leva_evaluation_results.details`: an evaluator may return `[score, details]` or `{score:, details:}` and the details (a judge's reasoning, the failed assertion) are stored and shown on the runner result page and as the score's tooltip in the experiment table
- An evaluator may return `nil` to abstain — nothing is stored for that run (a skipped case, a rubric that does not apply)
- `Leva.config.default_model`: the model the experiment form proposes for LLM runners — an id or a callable read per request, so a host can point it at its own runtime default (default `Leva::PromptOptimizer::DEFAULT_MODEL`); a default the RubyLLM registry does not list is shown as typed instead of leaving the field blank

### Changed
- Stimulus 3.2.2 ships with the engine (`app/assets/javascripts/leva/stimulus.umd.js`, the npm package's own UMD build, served through the asset pipeline) instead of being loaded from `cdn.jsdelivr.net`, so the UI works without egress and a host's script CSP can stay `'self'`
- Runner results no longer require a `Leva::Prompt` (`prompt_id` is nullable; `execute_and_store(experiment, dataset_record, prompt = nil)`), so a runner that owns its prompt — an application's production prompt, a fixed pipeline — stores results, and an experiment created with the form's "None" prompt runs instead of failing
- `BaseEval#evaluate` receives the `Leva::RunnerResult` (as it always did at runtime); the documentation now says so

## [0.3.4] - 2025-12-17
### Fixed
- Relaxed Liquid gem version constraint from `~> 5.5.0` to `~> 5.5` to allow newer versions (Fixes #30)

## [0.3.3] - 2025-12-08
### Added
- `to_dspy_context` method support for recordables - allows separate DSPy-specific context (falls back to `to_llm_context`)
- Documentation for `to_dspy_context` in README

### Changed
- DSPy optimized prompts now use DSPy-style format: instruction + examples + labeled input fields in user prompt
- Context values are sanitized to strings for DSPy signature compatibility

### Fixed
- Removed `system_prompt` presence validation to support DSPy-style prompts without system prompts

## [0.3.2] - 2025-12-08
### Fixed
- Added missing optimization routes and UI for DSPy prompt optimization feature
- Fixed `@evaluator_classes` undefined variable error when rendering experiment partials on dataset show page

## [0.3.1] - 2025-12-06
### Added
- **DSPy Prompt Optimization** - Automatic prompt optimization powered by DSPy.rb
  - `PromptOptimizer` service for finding optimal prompts and few-shot examples
  - Three optimizer strategies: Bootstrap (fast), GEPA (best quality), MIPROv2 (thorough)
  - `DatasetConverter` for converting datasets to DSPy format
  - `SignatureGenerator` for creating DSPy signatures from datasets
  - `OptimizationRun` model for tracking optimization progress
- Documentation in README for prompt optimization usage

### Changed
- CI now uses `.ruby-version` file for consistent Ruby version (3.3.0)
- Ruby 3.3.0+ required for DSPy features (io-event gem dependency)

## [0.3.0] - 2025-12-06
### Changed
- Maintenance release with dependency updates and code cleanup

### Fixed
- Cleaned up incomplete code from previous development work
- Fixed CI pipeline issues

## [0.2.1] - 2025-11-23
### Changed
- Improved workbench UI with better spacing and visual hierarchy in output section
- Hidden scrollbars while maintaining scroll functionality for cleaner appearance
- Added visual accents for EXPECTED, RESULT, and PARSED blocks

## [0.2.0] - 2025-11-22
### Fixed
- Asset loading for Rails apps using Sprockets or Propshaft by properly configuring asset paths in the engine initializer

## [0.1.11] - 2025-11-22
### Added
- Comprehensive CSS design system with custom properties for colors, spacing, typography, and transitions
- Design system reference page at `/design-system` with documented component patterns
- Collapsible left sidebar with dot indicators when collapsed
- Resizable right panel with localStorage persistence
- Stimulus JS controllers for collapse and resize interactions

### Changed
- Improved page layouts with better spacing, responsive breakpoints, and overflow handling
- Updated all views to use design system CSS classes and custom properties
- Button consistency improvements across all pages with documented usage guidelines
- Dark theme optimized for AI/developer tools

### Fixed
- Right-side overflow on experiments table
- Consistent margin handling between workbench and standard pages

## [0.1.10] - 2025-01-16
### Added
- Runner-specific LLM context support via `BaseRun#to_llm_context(record)` for expensive operations
- Visual separation of record vs runner context in workbench UI
- Routes mounting instructions to Installation section (Thanks @robzolkos!)

### Fixed
- NoMethodError when viewing empty dataset records (Thanks @robzolkos!)
- Added defensive UI for missing runners in new experiment form (Thanks @robzolkos!)
- Code block formatting in documentation (Thanks @ttilberg!)
- Migration order: ensure CreateLevaRunnerResults runs before CreateLevaEvaluationResults (Thanks @RutSzymon!)
- Various asset loading and importmap issues

### Changed
- Reduced the number of migrations for cleaner database setup (Thanks @RutSzymon!)
- Reverted experimental asset changes for stability

### Contributors
Special thanks to the following contributors for their work on this release:
- @robzolkos - Multiple UI fixes and documentation improvements
- @RutSzymon - Migration optimizations and ordering fixes
- @ttilberg - Documentation formatting improvements

## [0.1.9] - 2025-04-25
### Added
- Collapsible prompt preview with dialog for long content
- Scrollbar for long content in prompt preview

### Changed
- Moved JavaScript to inline code for simpler implementation

## [0.1.8] - 2025-03-12
### Added
- RubyGems badge in README.md
- CHANGELOG.md file for tracking project changes

### Fixed
- Text overflow issues in workbench UI for long prompts and results
- Improved textarea and preview areas with proper word wrapping
- Added global CSS for better handling of long text in all pre and textarea elements

## [0.1.7] - 2024-09-12
### Added
- `runner_class` attribute to `RunnerResult` model

### Changed
- Refactored ExperimentJob to schedule dataset records for evaluation in parallel
- Updated runner_class attribute handling in RunnerResult

## [0.1.6] - 2024-08-26
### Changed
- Improved RunnerResult functionality for parsed predictions extraction
- Modified RunnerResult to use perform_later for running evaluations in ExperimentJob

## [0.1.5] - 2024-08-23
### Added
- Display of parsed predictions in runner results view
- Margin-bottom to parsed predictions in _results_section.html.erb

### Changed
- Enhanced `evaluate_and_store` method in Leva module to store experiment and runner result
- Improved parsed predictions extraction in RunnerResult

## [0.1.0] - 2024-08-13
### Added
- Initial release
- Core models for datasets, experiments, prompts, and evaluation
- Basic UI for workbench and experiment management
