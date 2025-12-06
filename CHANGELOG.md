# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
