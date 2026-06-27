# Changelog

All notable changes to this project are documented here. The format loosely
follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- `.editorconfig` for consistent indentation, line endings and final newlines
  across Bicep, YAML and JSON files.
- `logDailyQuotaGb` parameter on the `secure-platform` composition to cap daily
  Log Analytics ingestion. Dev caps at 5 GB/day; prod stays uncapped.

### Changed
- `secure-platform` README parameter table now lists `logDailyQuotaGb`.
