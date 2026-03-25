# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/).


## [Unreleased]

_No unreleased changes yet._

## [1.2.0] — 2025-12-10

### Added

- Added full CSV validation script (`ci/check_csv.rb`) to replace inline Ruby logic.
- Added fallback directory checks for file references: `objects/`, `items/`, `assets/`, and project root.
- Added automatic skipping of external URLs (`http://`, `https://`, `//`), `data:` URIs, IIIF resources, and bare `objectid` values without file extensions.
- Added ANSI colorized output for easier CI log readability.
- Added machine-readable JSON report (`build-report.json`).
- Added human-readable CI log artifact (`build.log`).
- Added support for environment variable overrides (`CB_ITEMS_CSV`, `CB_REQUIRED_HEADERS`).
- Added GitLab runner targeting for builds using `tags:`.

### Changed

- Consolidated CI validation into a single script: `ci/build_check.sh`.
- Improved file column detection with flexible patterns: `file|image|object|path|filename`.
- Improved error output and summaries for missing headers, values, and files.
- Updated Jekyll calls to use `bundle exec jekyll` to avoid PATH issues.
- Enhanced pipeline logs for clearer output during validation.

### Fixed

- Fixed false-positive “missing file” errors for rows not referencing actual paths.
- Fixed Bundler permission issues by ensuring correct `bundle` path and installing Git for gems requiring Git sources.
- Fixed inconsistent Jekyll availability on GitLab runners.


## [1.0.1] - 2025-12-10

### Changed

- Introduced new CI helper script `ci/build_check.sh` to consolidate all build-validation logic into a single, executable Bash script.
- Updated `build` pipeline to use a bundle directory writable by the Jekyll user, fixing permission errors in CI.
- Added `apk add --no-cache git` to support Bundler when gems depend on Git repositories.

## [1.0.0] - 2025-11-21

### Added

- Added Changelog to track project changes.
- Added initial `.gitlab-ci.yml` for `build` pipeline.
- Added Code Owners file.
