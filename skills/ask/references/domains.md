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

**Deploys across a team tree:** deploys are attributed to teams, not people, so `Team.name = "X"` returns that team's own deploys only (not its sub-teams) and the `Person` hierarchy pattern doesn't apply. To total a team and all of its sub-teams, use the groups-mode `Team.groupPath` `DESCENDANT_OF` roll-up in SKILL.md → "Deployment metrics across a team tree". It de-duplicates across teams in one query, so don't fetch per-team rows and sum them, and don't mix deploy metrics with person metrics in the same groups-mode query.

**MTTR aggregation types:** MTTR supports `avg`, `p50`, `p75`, `p90`, and `max`. Choose based on intent:
- `avg` — overall average recovery time
- `p50` — typical recovery (median)
- `p90` — worst-case excluding outliers
- `max` — absolute worst case

**Org-wide DORA deployments:** Do NOT use `Team.name = "Organization"`. Deploys are leaf-only on `Team.name`, so it returns only that team's own deploys (usually ~0), not the company total. For an org-wide deployment total you MUST use the groups-mode `Team.groupPath` `DESCENDANT_OF` roll-up anchored at the **org root group path** — see SKILL.md → "Deployment metrics across a team tree". Do not manually aggregate across services or teams.

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

**Not the same as AI Traces.** This domain measures AI's footprint on the *codebase* (what share of code is AI-authored, what the tools cost, who has a seat). AI Traces measures what happened *inside agent sessions*. "How much AI do we use?" is this domain; "which skills do people invoke, and what do their agents do?" is AI Traces — see below.

## AI Traces

**Assets:** Trace (a session), TraceTurn (its turns), TraceEvent (its events)

Fields, filters, operators and page caps are described per field in the facade metadata — read them there. Below is only what the metadata can't tell you.

**A missing facade is not a zero.** The whole domain is gated together: when the org doesn't have AI traces enabled or the token lacks trace access, the facades, the trace metrics *and* the `aiTrace*` dimensions are all absent from metadata — so the aggregate plane is no fallback for the corpus plane, and a metric search that comes up empty is the same signal. If they're still missing after a refresh, say "AI traces aren't enabled for this org (or this token lacks trace access)" — never "no agent activity".

**Match the question to the shape:**

| Question | Query |
|----------|-------|
| "How much are we running agents?" — sessions, active users, cost, autonomy ratio | Trace metrics on `Person` or `Team` (search the cache — that's where they're exposed), or `Trace` in groups mode by `aiTraceTool` / `aiTraceModel` / `aiTraceTaskCategory` (a dimension — grouping by the Author or Team relation is rejected) |
| "What happened inside sessions?" — skills, prompts, failures, files | `TraceEvent` with **no** `traceId`: a corpus search across every session you can read |
| "Which sessions did X happen in?" | `Trace` with an `eventCount` filter |
| "Walk me through this session" | `Trace.id` → `TraceTurn(traceId)` → `TraceEvent(traceId, turnIndex)` |
| "Which sessions worked on issue X / in repo Y?" | `Trace` via the `Issues` or `Repositories` relation (catalog entities; `Issue.Traces` goes the other way). `Trace.Issues` carries only `id`, so resolve the issue first. The `repos` field is the raw remote name as the session saw it, not the catalog repository |

**Three levels, and a rule for stopping.** Trace is the *frame* — what kind of work, how hard. TraceTurn is the *behavior* — how the person drove the agent, where most signal lives and the cheapest place to find it. TraceEvent is the *evidence* — the exact prompt or tool output, read to ground a citation. Start at the frame, analyze at the turn, cite at the event, and **stop at the shallowest level that supports the claim**. Event bodies dominate everything else: on a real corpus they run roughly 20× the turn digests and 450× the frame, and here the binding limit is the conversation itself, so descend deliberately and on a handful of exemplars.

**TraceEvent and TraceTurn carry no metrics** and no server-side grouping — one row per event or turn — so "which skills are most used" means paging rows and aggregating them yourself; send `"metrics": []`. This is the one place in this skill where client-side aggregation is correct. **But filter server-side first:** the frame's magnitude counts are filterable and sortable, so "sessions with more than two skill uses" is `skillUsesCount > 2` rather than a page-and-count; a named skill or repo is an `eventCount` filter; and the per-turn magnitude filters (`toolCalls`, `fileWrites`, `subagents`, `skillUses`, `durationMs`, `activeMs`, `boundary`) locate the interesting turns without reading a single body. `durationMs` is `activeMs` plus the stalls itemised in `gaps` (e.g. `awaiting_human`), so a long turn with low `activeMs` stalled rather than worked; a null `activeMs` predates the measurement and is not zero. Aggregate client-side only for what no filter or metric expresses.

**One root facade per query.** `Trace` and `TraceEvent` cannot be joined — selecting across both is a 400. `authorEmail` is the bridge back to a person on the event and turn facades; `traceId` is the bridge back to a session.

**Turn shapes** — how rollups become readings. Each is a hypothesis to confirm at the event level, and each reads differently depending on task category and complexity:

| Shape | Turn signals | Reading |
|-------|--------------|---------|
| One-shot | one `user_act` turn, `fileWrites > 0`, modest `toolCalls`, no correction after | effective, autonomous |
| Thrash | high `toolCalls` with low or zero `fileWrites`; or repeated writes to one file | spinning — wrong approach or missing context |
| Correction loop | many short consecutive `user_act` turns, small rollups | over-steering, or an unclear opening prompt |
| Hand-holding | many user turns, no subagents, on complex work | low autonomy — delegate or front-load context |
| Delegation | `subagents > 0` on a complex session | parallel work; a strength |
| Explore-heavy | `fileReads` far exceeding `fileWrites`, sustained | healthy for exploration, a stall on a trivial fix |

**Corpus recipes** (all `TraceEvent`, no `traceId`):

| To find | Filter | Note |
|---------|--------|------|
| Which skills exist / are most used | `toolChannel = 'skill'`, no `toolName` | one row per invocation; group by `toolName` yourself — names have no wildcard match |
| One named skill | `toolChannel = 'skill'` + `toolName` | |
| MCP tool usage | `toolChannel = 'mcp'` | |
| What people typed as prose | `eventTypes = 'user_prompt'` | **plain prompts only.** A typed `/slash` command is recorded as the skill invocation it names, not as a prompt, so this undercounts what people actually asked for |
| Everything a person initiated | `initiatedBy = 'user'` | prompts *and* typed commands; `'agent'` gives the model's own dispatches, and the two partition the same rows |
| Runs that failed | `success = false` | `null` means no outcome reported, not a pass |
| Files edited, not merely touched | `eventTypes = 'file_change'` + `fileOperation = 'modify'` | one row per file, not per tool call — a single edit act can touch several |
| An error phrase in tool output | top-level `search` | BM25 covers what an act was asked to do *and* what it produced, so "permission denied" finds the run that emitted it |

**An empty result is ambiguous — the biggest trap in this domain.** Session *metadata* (counts, duration, tool, author, cost) is visible for every session you can list, but session *content* — prompts, tool calls, turn digests, the whole TraceEvent/TraceTurn surface — is limited to authors whose content you may read, often just your own. It fails soft: 200 with zero rows, not an error. So before reporting any corpus finding, compare the distinct authors in your event rows against the distinct `Trace.Author.email` for the same window. One author out of twenty means you surveyed your own usage — say so in the headline. This also makes some questions only half-answerable: `Trace.skillUsesCount` gives you skill invocations per session — and so how many sessions used *any* skill — for every session you can list, but *naming* the skill is content-scoped. **A listed session can still be a stub.** Screening holds some sessions back from everyone but their author — including every session from before 2026-09-01. You see the row and its metadata, but the title is a placeholder derived from the trace id, and there is no eval, turn or event behind it. Don't read placeholder titles as what people worked on, and count stubs before reporting coverage. A session screening hasn't reached yet isn't listed at all, for anyone. Check the window too — if the returned `firstEventAt` values stop well inside the range you asked for, the corpus doesn't span it; widen and report the real range rather than reading a young corpus as a decline.

**Rank eval and classification fields yourself.** `evalOverallScore`, `cost`, `complexity`, `taskCategories` and `title` are select-only (the metadata says so per field), so "the worst-scoring sessions" can't be a server-side sort — select over a bounded window and order client-side.

**Calibrate, and don't build a scoreboard.** Judge every signal relative to task category × complexity, never raw magnitude — 25 tool calls in one turn is healthy for a complex refactor and a smell on a trivial fix. Never rank people by eval score or print individual scores; describe patterns, not performance, and treat unevaluated as unevaluated rather than bad. Don't drill only the failed or low-scoring sessions — that is the most common way to reach a biased finding; span the range and include at least one clean session for contrast. Cite by trace id + turn index, treat a single occurrence as a one-off, and remember you only see the trace: a missing verification step may mean the environment blocked the agent, not that the person skipped it.

## Calendar

**No dedicated asset.** Calendar metrics (focus time, meeting hours, fragmented time, maker time) live on **Person** and **Team**.

**Focus vs focus time:** Do NOT confuse "Focus" (investment focus areas / work allocation) with "focus time" (calendar-based uninterrupted work blocks). These are completely different concepts from different domains.

**No attendee-based queries.** The API cannot find meetings by attendees or intersect calendars across people. Calendar data is per-person aggregates only.
