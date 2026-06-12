# Changelog

All notable changes to this project will be documented in this file.

## [1.3.0] - 2026-06-12

### Fixed

- Corrected org-wide DORA deployment guidance: org-wide and subtree deployment totals must use the `Team.groupPath` `DESCENDANT_OF` roll-up, not `Team.name = "Organization"` (deploys are leaf-only on `Team.name`)

### Added

- Complete copy-pasteable groups-mode example for the deployment roll-up
- Guidance on finding the org root team (the `Team.path` with no `.`)

## [1.2.0] - 2026-06-12

### Changed

- Promoted the `ask` skill to general availability
- Expanded guidance on DORA metric roll-up edge cases

### Added

- Client meta header on query requests
- Guidance on common facade mistakes

### Documentation

- Added Cursor usage notes

## [1.1.0] - 2026-02-04

### Security

- Improved token handling at configuration check

### Documentation

- Added required tools section to README (`curl`, `jq`)
- Added installation instructions for dependencies

## [1.0.0] - 2026-01-29

- Initial release
