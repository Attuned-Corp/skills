# Domain-Specific Query Guidance

Load this reference when a query touches one of these domains. Each section documents caveats, asset choices, and patterns that differ from the general query workflow.

## Productivity

**Assets:** PullRequest, Issue, Epic, Sprint, Commit

**PullRequest time dimension:** PullRequest has ONLY `ts` as a time dimension. There is no `mergedAt` or `createdAt` dimension. To filter by merge date, use the `extMergedAt` catalog field in filters — not `dimensionName`.

**Author vs Reviewer:** PullRequest has separate author and reviewer dimensions. If the user asks about "PR activity" without specifying, clarify whether they mean authored PRs, reviewed PRs, or both.

**Issue vs Epic vs Sprint:** These are separate assets (facades), not filters on a single asset. Epic is a filtered view of Issue but queried as its own asset. Sprint is a distinct asset — do not query it from Issue.

**Relation-only assets:** Summarization and WorkTheme are relation-only — they cannot be queried independently. Access them via relations on other assets (e.g., `PullRequest.Summarization`).

## DORA

**Two facades, four metrics:**
- **Deployment** — deployment frequency, lead time for changes
- **Incident** — MTTR, incident count

**Change failure rate** is a composite metric (incidents / deployments). It is not a single direct field — check metadata for how it is exposed. It may require querying both Deployment and Incident data.

**MTTR aggregation types:** MTTR supports `avg`, `p50`, `p75`, `p90`, and `max`. Choose based on intent:
- `avg` — overall average recovery time
- `p50` — typical recovery (median)
- `p90` — worst-case excluding outliers
- `max` — absolute worst case

**Org-wide DORA:** Query `Team` filtered by `Team.name = "Organization"`. Do not manually aggregate across services or teams.

## Investment

**FTE Days** is the universal effort metric for investment queries. Search metadata for it by label.

**Four distinct investment views** — each uses different dimensions and query patterns:

| View | What it shows | Key dimension |
|------|--------------|---------------|
| **Inferred** | Effort by work type (feature, maintenance, etc.) | Automatically classified from git/issue data |
| **Labeled** | Effort by user-applied labels | Requires labels to be configured |
| **Workstreams** | Effort by strategic initiative | Workstream is relation-only — access via `Team.Workstream` |
| **Cost Capitalization** | Effort split for accounting (capex vs opex) | Has separate metrics from FTE Days |

**Team vs Epic effort:** Team-level effort is more complete than Epic-level. Epic effort only captures work explicitly linked to epics — unlinked work is missing. Prefer Team queries for totals.

**Clarify inferred vs labeled:** If the user asks "where is effort going?" without context, ask whether they want inferred categories (automatic) or labeled categories (manual tags).

## AI Transformation

**AiToolUsage is relation-only.** It cannot be queried as a standalone asset. Access it via `Team.AiToolUsage` or `Person.AiToolUsage`.

**AI code ratio** metrics live on **PullRequest**, not on a dedicated AI asset. To get org-wide AI code ratio, query `Team` with the AI code ratio metric.

**Spend vs usage:** AI spend metrics (cost) are separate from AI usage metrics (adoption rate, active users). Don't conflate them.

**Grouping by tool/model:** AiToolUsage has dimensions for tool name and AI model, allowing breakdowns like "AI usage by tool" or "spend by model."

## Calendar

**No dedicated asset.** Calendar metrics (focus time, meeting hours, fragmented time, maker time) live on **Person** and **Team**.

**Focus vs focus time:** Do NOT confuse "Focus" (investment focus areas / work allocation) with "focus time" (calendar-based uninterrupted work blocks). These are completely different concepts from different domains.

**No attendee-based queries.** The API cannot find meetings by attendees or intersect calendars across people. Calendar data is per-person aggregates only.
