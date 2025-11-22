# Release Gem

Release a new version of the Leva gem to RubyGems.

## Instructions

Follow these steps to release version **$ARGUMENTS** of the gem:

### 1. Pre-release checks
- Run `bundle exec rubocop` to check for style violations
- Run `bundle exec rails test` to ensure all tests pass
- If either fails, stop and fix the issues before continuing

### 2. Update version
- Update the version in `lib/leva/version.rb` to `$ARGUMENTS`

### 3. Update CHANGELOG.md
- Move any items under `[Unreleased]` to a new section `[$ARGUMENTS] - YYYY-MM-DD` (use today's date)
- If there are no unreleased items, ask the user what changes should be documented

### 4. Commit the version bump
- Stage all changes: `git add -A`
- Commit with message: `Bump version to $ARGUMENTS`

### 5. Release to RubyGems
- Run `bundle exec rake release` which will:
  - Build the gem
  - Create git tag `v$ARGUMENTS`
  - Push tag to GitHub
  - Push gem to RubyGems.org

### 6. Confirm success
- Verify the release was successful by checking the output
- Provide the user with the RubyGems URL: https://rubygems.org/gems/leva

**Important:** If no version argument is provided, ask the user what version they want to release. Show them the current version from `lib/leva/version.rb` first.
