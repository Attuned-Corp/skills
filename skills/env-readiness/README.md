# env-readiness

Investigate a repository's environment-readiness recommendations and produce a prioritized plan.

## What it Does

Environment-readiness recommendations are mined from real AI-coding-agent traces. Each one flags a
gap in a repo or its tooling that made it harder for an agent to find context, follow conventions,
or verify its own changes — and proposes a fix.

This skill:

1. **Determines the repository** from the working directory's git remote (asks if ambiguous).
2. **Fetches the recommendations live from Span** via the Span MCP server (`TraceRecommendation`),
   scoped to that repo.
3. **Investigates each one** against the actual codebase — reading files and history, and
   **running the exact commands** a recommendation describes to reproduce (or refute) the friction.
4. **Prioritizes and prints a plan**: which recommendations to implement now, which are
   already-resolved or environment-only, and — for each implementable one — a repo-grounded fix and
   how to verify it.

It classifies every recommendation as `implement-now`, `environment-only`, `already-resolved`, or
`insufficient-evidence`, and ranks the implementable ones by impact × fix-confidence × effort ×
risk.

## Plan only

The skill **makes no changes and writes no files**. It may run read-only and reproduction commands
(build, typecheck, lint, test, git) but never edits tracked files, creates branches, commits, or
persists output — the plan is printed to the conversation for a human to review and act on.

## Prerequisites

- The target repository **checked out locally** (the skill runs commands against it).
- The **Span MCP server** connected, with access to the tenant's `TraceRecommendation` data.

## Usage

Invoke with `$span:env-readiness` in Codex or `/span:env-readiness` in Claude Code,
or ask naturally - e.g. "improve this repo's AI-agent readiness" or "act on our
env-readiness recommendations". Optionally pass a repo name/path or a focus
hint as an argument.

## Skill Structure

```
env-readiness/
├── SKILL.md    # Core skill prompt
├── README.md
└── VERSION
```
