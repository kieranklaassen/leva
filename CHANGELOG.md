# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
