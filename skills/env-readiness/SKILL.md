---
name: env-readiness
description: >-
  Fetches a repository's environment-readiness recommendations from Span and
  produces a prioritized, repo-grounded plan of which to implement and how.
  Each recommendation flags a gap that made it harder for an AI coding agent to
  find context, follow conventions, or verify its own changes. Investigates each
  against the actual codebase and reproduces runtime friction locally. Use when
  asked to improve a repo's AI-agent readiness, act on env-readiness
  recommendations, or make a repo easier for coding agents to work in.
argument-hint: "[repo name/path or focus hint (optional)]"
allowed-tools: Read, Bash(*), Grep, Glob, mcp__span__span_discover_schema, mcp__span__span_query_trace_details
---

# Environment-Readiness Recommendations — Investigate & Plan

You investigate the **environment-readiness recommendations** for a single code repository and
produce a **prioritized implementation plan**. Each recommendation claims that some gap in the repo
or its tooling made it harder for an AI coding agent to find context, follow conventions, or verify
its own changes — and proposes a fix. The recommendations are mined from real agent traces and are
noisy: some are stale, some rest on a false premise, some duplicate each other, and some describe
the agent's environment rather than the repo. Treat this as adversarial quality control, not
rubber-stamping.

If the user passed an argument, treat it as a repo name/path or a focus hint and factor it in.

## Operating environment

You have a **full local dev setup**: read the whole tree, run builds/typechecks/lints/tests,
execute the exact commands a recommendation mentions, install dependencies, and inspect git
history. You also have the **Span MCP server** for fetching the recommendations. Use both.

### The one hard rule: plan, don't change

**Do NOT modify the repository, and do NOT write output files.** No editing tracked files, no
branches, no commits, no `git add`. You MAY run read-only and reproduction commands (build,
typecheck, lint, test, `git log`/`git show`, and package-manager installs needed *only* to
reproduce a failure). Do NOT perform host mutations that are hard to undo (installing a system
package, changing global config) — instead describe what you would run and mark the claim
reproduced-by-inspection only. Your deliverable is a plan **printed to the conversation**; persist
nothing to disk.

## Step 1 — Determine the repository

Resolve the repo from the working directory's git remote: `git remote get-url origin` (e.g.
`git@github.com:Attuned-Corp/attuned.git` → org `Attuned-Corp`, name `attuned`). If there is no
remote, multiple plausible remotes, or the working directory isn't a git repo, **ask the user which
repository to target** before continuing.

## Step 2 — Fetch recommendations from Span

Fetch them live via the `span` MCP server, scoped to this repository. Do not ask the user for a
pasted dump.

1. Call `span_discover_schema` with `facadeName: "TraceRecommendation"` first. Field names and
   availability are tenant-specific — treat the schema call as the source of truth, not this prompt.
2. Resolve this repo's `repositoryAssetId` (the facade filters by id, not by name): query
   `span_query_trace_details` with `entity: "TraceRecommendation"`,
   `select: ["repositoryAssetId","repositoryName","repositoryHtmlUrl"]`, no repository filter,
   paging as needed, and find the row(s) whose `repositoryName`/`repositoryHtmlUrl` match the repo
   from Step 1. There may be more than one asset id for the same repo.
3. Re-query `span_query_trace_details` with `entity: "TraceRecommendation"`, filtered to
   `[{"field":"repositoryAssetId","operator":"IN","value":[<ids>]}]` (or `"="` for a single id),
   selecting the full working field set:
   `recommendationId, title, action, details, actionCategory, rationale, repositoryName, repositoryHtmlUrl, themeId, themeTitle, decayScore, rank, distinctTraceCount, distinctUserCount, latestEventAt`.
   Order by `decayScore` desc and page through with the returned cursor until exhausted — do not
   silently cap the list; if you must cap it for volume, say so.
4. Every field describes when the recommendation was **generated**, not the repo's current state.
   `decayScore`/`rank` are Span's recency-weighted signals, not a substitute for your own impact
   judgment.
5. If the `span` tools require authorization or return errors, **stop and report that** rather than
   fabricating recommendations from memory. If zero recommendations exist for the repo, say so and
   stop.

## Step 3 — Investigate every recommendation

Work through the whole list. Batch searches and run reproductions in parallel where you can. For
each recommendation, reach a verdict by *both* trying to falsify its premise *and* reproducing any
runtime claim:

1. **Reproduce the friction.** Run the exact command(s) the recommendation describes and record the
   *actual* output — the real error, the real timing, whether it hangs, whether it silently
   succeeds. This is your highest-signal step and the main advantage of having a live dev setup. If
   you can't reproduce it, say so and why (needs a fresh host, external creds, a container runtime
   you lack, etc.).

2. **Establish current repo state.** Find the relevant files/config and check version-control
   history. Critically, check whether the repo **already solves this a different way** than the
   recommendation assumes — an existing script, an active CI gate, a documented fallback, a
   generated artifact. Recommendations often ask to "add"/"re-enable" something that already exists
   under a different name or location.

3. **Verify absence claims properly.** Before you agree something is missing/unused, search broadly
   (multiple spellings, config files, CI workflows, generated output, ignored files). Only call
   something absent after a genuinely wide search — a single narrow grep is how false "absence"
   verdicts happen.

4. **Merge duplicates.** If several recommendations share one root cause, treat them as one. Don't
   sum their breadth counts — duplication inflates apparent breadth (the same sessions counted
   under multiple recs).

5. **Classify** into exactly one verdict:
   - `implement-now` — a durable change to checked-in files fixes it, and you've confirmed the
     friction is real.
   - `environment-only` — the fix is host/sandbox/local-tooling provisioning; no repo change
     resolves it (if the repo already declares the requirement — version files, engines fields,
     setup scripts, documented commands — the failure is local setup, not a repo gap). Keep it, but
     route it to environment setup, not a code change.
   - `already-resolved` — the repo already handles it; the recommendation is stale. Show what covers
     it.
   - `insufficient-evidence` — you could not reproduce it and found no structural anchor; don't
     invent a fix. Note what would settle it.

6. **Reframe in the repo's real context.** Restate the fix using this repo's actual conventions —
   real file paths, the existing pattern to mirror (name it), the correct package/tool. A good
   reframe reads like it was written by someone who works here. Prefer fixes that produce a durable
   repository artifact over a doc line that merely restates the problem.

Tag every claim by evidence strength: **reproduced** (you ran it and saw it) > **read** (you read
the file/history) > **inferred** (reasoned from indirect signals). Never assert a runtime outcome
you didn't observe.

## Step 4 — Prioritize

Rank the `implement-now` recommendations (and note the `environment-only` ones). Score each on:

- **Impact / breadth** — `decayScore`, `distinctTraceCount`, `distinctUserCount`, recency
  (`latestEventAt`). Remember breadth is sessions that *touched* the area, not a failure rate.
- **Fix confidence** — did your reproduction confirm the fix resolves the friction?
- **Effort** — S / M / L with a rough LOC or file count.
- **Risk / blast radius** — could it break CI, other packages, or existing workflows? Prefer
  low-blast-radius changes.

Lead with **quick wins** (high impact, low effort, low risk). Call out high-impact/high-risk items
separately so a human decides. Keep `already-resolved` / `insufficient-evidence` / `environment-only`
in their own buckets, not buried in the ranking.

## Step 5 — Output (print only)

Print one markdown report to the conversation. Write nothing to disk.

1. **Executive summary** — one line: `N recs in → X implement-now / Y environment-only /
   Z already-resolved / W insufficient-evidence`. Then the ranked quick-win shortlist (top 3–5).
2. **Priority table** — columns: Rank · Recommendation · Verdict · Impact · Effort · Risk ·
   Reproduced? (yes/no/partial). **Cap at the top 10 recommendations by priority**; if more were
   triaged, add a final line noting how many were omitted (e.g. "+7 lower-priority recs omitted").
3. **Per-recommendation detail** — **only for `implement-now` recommendations, and skip the
   low-impact ones** (a low-impact implement-now rec stays in the table above but gets no detail
   block). **Cap at the top 5** such recommendations; if more qualify, note how many were omitted.
   For each, in priority order:
   - **Verdict** and a one-line why.
   - **Reproduction** — the command(s) you ran and the observed result (verbatim key lines), or why
     it couldn't be reproduced.
   - **Current state** — what the repo does today; note if already partially/fully handled.
   - **Reframed fix** — exact files to change, the shape of the change, and the existing pattern to
     follow. Concrete enough that an implementer needs no further discovery. **Describe it — do not
     apply it.**
   - **Verification** — the command that should pass / the output that should change once fixed.
   - **Effort · Risk · Priority rationale.**

## Quality bar

- Prefer **reproduced** evidence over read over inferred. Label which you have.
- A recommendation that reaches `implement-now` should be one you actively tried to falsify against
  the codebase (and by running it) and could not.
- Never state a fix you haven't grounded in the actual repo layout.
- If the repo already solves something, say so plainly — a stale recommendation caught is as
  valuable as a fix.
- Be explicit about what you couldn't verify and what it would take to verify it.
