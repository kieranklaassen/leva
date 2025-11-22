# Release Gem

Release a new version of the Leva gem to RubyGems.

## Instructions

Follow these steps to release version **$ARGUMENTS** of the gem:

### 1. Pre-release checks
- Ensure working directory is clean: `git status`
- If there are uncommitted changes, stash them: `git stash`
- Run `eval "$(rbenv init -)" && bundle exec rubocop` to check for style violations
- Run `eval "$(rbenv init -)" && bundle exec rails test` to ensure all tests pass
- If either fails, stop and fix the issues before continuing

### 2. Update version
- Update the version in `lib/leva/version.rb` to `$ARGUMENTS`
- Run `bundle install` to update Gemfile.lock with the new version

### 3. Update CHANGELOG.md
- Move any items under `[Unreleased]` to a new section `[$ARGUMENTS] - YYYY-MM-DD` (use today's date)
- If there are no unreleased items, ask the user what changes should be documented

### 4. Commit the version bump
- Stage all changes including Gemfile.lock: `git add lib/leva/version.rb CHANGELOG.md Gemfile.lock`
- Commit with message: `Bump version to $ARGUMENTS`

### 5. Release to RubyGems
- Run `eval "$(rbenv init -)" && bundle exec rake release` which will:
  - Build the gem to `pkg/leva-$ARGUMENTS.gem`
  - Create git tag `v$ARGUMENTS`
  - Push tag to GitHub
  - Attempt to push gem to RubyGems.org

### 6. Handle OTP for RubyGems
- If rake release fails due to OTP, the git tag was still pushed successfully
- Tell the user to run manually: `gem push pkg/leva-$ARGUMENTS.gem`
- This will prompt for their RubyGems OTP code

### 7. Confirm success
- Verify the release was successful
- Provide the user with the RubyGems URL: https://rubygems.org/gems/leva
- Pop any stashed changes if needed: `git stash pop`

**Important:**
- If no version argument is provided, ask the user what version they want to release. Show them the current version from `lib/leva/version.rb` first.
- Always use `eval "$(rbenv init -)"` before bundle commands to ensure correct Ruby version
- The Gemfile.lock MUST be committed as it contains the gem version
