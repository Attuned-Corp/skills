# Changelog

All notable changes to this project will be documented in this file.

## [1.5.0] - 2026-09-29

### Removed

- The `env-readiness` skill. The trace recommendations it read are retired; environment readiness now lives on the Harness health page in Span, and the MCP server no longer offers the recommendation tools the skill called
- The trace recommendation entity from the `ask` skill's AI Traces domain, and the routing note that sent recommendation questions to `env-readiness`

### Added

- `ask` AI Traces: routing for sessions by issue or repository through the `Trace.Issues` and `Trace.Repositories` relations
- `ask` AI Traces: turn timings, where `durationMs` splits into `activeMs` plus the stalls in `gaps`
- `ask` AI Traces: screening stubs, which are listed sessions with a placeholder title and no content for non-authors, including every session before 2026-09-01

### Changed

- Client meta version bumped to `skill/2026-09-29`

## [1.4.0] - 2026-08-04

### Added

- **AI Traces domain** in the `ask` skill — query agent sessions and what happened inside them (skill and MCP usage, prompts, tool calls, file changes, per-turn behavior) across the `Trace`, `TraceTurn` and `TraceEvent` facades, with recommendation questions routed to the `env-readiness` skill
- Trace routing and corpus recipes in `references/domains.md`, including the scope check that keeps a content-limited result from being reported as an org-wide one
- The frame → turn → event ladder with a stop rule, a turn-shape vocabulary (thrash, correction loop, hand-holding, delegation, …), and the calibration and inference discipline that keeps trace findings from becoming a scoreboard
- Guidance to report a gated org as "not enabled" rather than as zero activity
- Two trace walkthroughs in `references/workflows.md`
- `search` and the `eventCount` filter documented in `references/api-reference.md`, along with trace response annotations and pagination differences

### Changed

- Client meta version bumped to `skill/2026-08-04`
- Trace corpus queries are exempt from the "never aggregate yourself" rule — those facades expose no metrics and no server-side grouping

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
