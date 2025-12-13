# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- CONTRIBUTING.md with development guidelines
- CHANGELOG.md to track project changes
- Shellcheck integration for code quality

### Fixed
- GitHub Actions workflow step references (steps.version → steps.get-version, steps.generate-links → steps.gen-links)
- Missing step IDs in release workflow
- Shellcheck warnings for utility scripts (added shebangs)
- Unsafe rm -rf operations with proper variable expansion (${var:?})
- Shellcheck warnings for IMEI and SERIAL_NO variables

### Improved
- Code quality with shellcheck validation
- Error handling in critical scripts
- Documentation structure

## [3.0.0] - 2025

### Core Features
- Based on latest stable Galaxy S22 firmware
- EROFS powered filesystem
- Galaxy S25 wallpapers and sounds included
- Galaxy AI support with multiple features
- High-end animations and blur support
- Multi-user and Samsung DeX support
- Debloated system services
- Custom FlipFont fonts support

### UN1CA-Exclusive Features
- Integrated OTA updates app
- Native/live blur toggle
- Vulkan renderer toggle
- Key attestation spoof (TrickyStore) options
- Play Integrity Fix integrated
- Ability to hide installed apps (Hide My Applist)
- Games FPS unlock toggle
- Unlimited backup storage on Google Photos

### Integrations
- BluetoothLibraryPatcher integrated
- KnoxPatch integrated
- Extra CSC features enabled

[Unreleased]: https://github.com/extremerom/UN1CA-v2/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/extremerom/UN1CA-v2/releases/tag/v3.0.0
