---
name: ask
description: >-
  Queries Span for organizational
  observability across five domains: productivity (cycle time, throughput,
  review metrics), DORA (deployment frequency, lead time, MTTR, change
  failure rate), investment (effort allocation, workstreams, cost
  capitalization), AI transformation (AI code ratio, adoption, spend),
  and calendar (focus time, meeting load). Use when asked about
  engineering metrics, team velocity, pull requests, commits, deployments,
  epics, issues, sprints, investments, teams, or people.
argument-hint: "<your question about engineering metrics>"
allowed-tools: Read, Write, Bash(*), Grep, Glob
---

# Span

If the user provided arguments with this invocation, treat `$ARGUMENTS` as their query and proceed directly (still ask for clarification if the time range is missing).

## Script & Path Setup

All bash commands in this skill should start by setting these two variables:

```bash
SPAN_DIR="${SPAN_CONFIG_DIR:-$HOME/.spanrc}"
SKILL_SCRIPTS="${CLAUDE_SKILL_DIR}/scripts"
```

Use `$SKILL_SCRIPTS/query.sh`, `$SKILL_SCRIPTS/fetch-metadata.sh`, etc. for all API operations. **Always prefer the scripts over inline curl commands.**

## Invocation Flow

1. **Check configuration state** — the dynamic context injection below tells you if the skill is configured
2. **If not configured** — run the First-Time Setup flow before anything else
3. **Check metadata cache** — load `$SPAN_DIR/metadata-cache.json`, or fetch if missing
4. **Ask clarifying questions** — especially for missing time ranges
5. **Plan query** — search metadata for metrics, choose asset level, use pre-aggregated metrics
6. **Execute query** — write query JSON to a temp file, run `$SKILL_SCRIPTS/query.sh`
7. **Format and return results** — convert units, handle pagination

## Configuration State

!`${CLAUDE_SKILL_DIR}/scripts/check-config.sh`

## First-Time Setup

If the configuration state above shows "api version mismatch", warn the user that their installed skill version may be incompatible with the current Span API, and suggest they update the skill. You may still attempt queries, but results may be unreliable.

If the configuration state above shows "not configured", you MUST run the onboarding flow before doing anything else:

1. **Create the configuration folder**:
   ```bash
   SPAN_DIR="${SPAN_CONFIG_DIR:-$HOME/.spanrc}"
   mkdir -p "$SPAN_DIR"
   ```

2. **Prompt user to add their token** to `$SPAN_DIR/auth.json`:
   ```json
   {
     "token": "your-personal-access-token"
   }
   ```

3. **Verify the token file exists** by running `$SKILL_SCRIPTS/check-config.sh` (never read `auth.json` directly).

4. **Fetch initial metadata**:
   ```bash
   $SKILL_SCRIPTS/fetch-metadata.sh
   ```

5. **Confirm setup is complete** and proceed with the user's original request.

### Configuration Directory

The skill stores configuration in `~/.spanrc/` by default. Override with `SPAN_CONFIG_DIR`:

```
~/.spanrc/                    # or $SPAN_CONFIG_DIR
├── auth.json                 # Span Personal Access Token (required)
└── metadata-cache.json       # Cached API metadata (auto-generated)
```

## Token Security (CRITICAL)

**NEVER read, print, or expose the Personal Access Token.** The scripts in `$SKILL_SCRIPTS/` handle authentication internally. You must NOT:
- Read `auth.json` (never use the Read tool on this file)
- Echo, print, or log the token value
- Construct inline `curl` commands with the token — use the scripts instead
- Include the token in error messages or output

## Clarifying Questions (IMPORTANT)

**Always ask clarifying questions rather than making assumptions.**

### Time Intervals

If the user's query does not specify a time range, **always ask before executing**:

> "What time period would you like me to query? For example: last 30 days, last quarter, or a specific date range. (If you'd like, I can default to the last 30 days.)"

**Do NOT assume a time range.** Even if the query sounds like it implies "recent" data, ask explicitly.

Examples requiring clarification:
- "How many PRs did we merge?" → Ask for time range
- "What's our cycle time?" → Ask for time range

Examples where time range is provided (no need to ask):
- "PRs merged last week" → Use last 7 days
- "Cycle time for Q4" → Use Q4 date range

### Other Ambiguities

Also ask for clarification when:
- **Team/person is unclear**: "Which team would you like me to query?"
- **Metric is ambiguous**: "Did you mean X or Y metric?"
- **Scope is unclear**: "Should this be organization-wide or for a specific team?"

## Metadata Caching

API metadata (assets, fields, metrics) is cached at `$SPAN_DIR/metadata-cache.json`. If the cache exists, use it. If not, run `$SKILL_SCRIPTS/fetch-metadata.sh`. Only refresh when the user explicitly asks to reload.

## Query Planning (MANDATORY)

Before executing any query, you MUST follow this process:

### Step 0: Verify Feasibility

Before building any query, confirm:
1. The requested metric exists in cached metadata
2. The requested asset type exists (Team, Person, PullRequest, etc.)
3. The metric is available on that asset type

**If verification fails, prioritize partial fulfillment:**
- Execute what IS possible, return available data
- Note what couldn't be included and why
- Suggest alternatives from available metrics/assets

Only refuse entirely when the core metric/asset is completely unavailable.

### Step 1: Check Available Metrics

**ALWAYS inspect the cached metadata to find relevant metrics:**

```bash
SPAN_DIR="${SPAN_CONFIG_DIR:-$HOME/.spanrc}"
cat "$SPAN_DIR/metadata-cache.json" | jq '.data[].metrics[]? | select(.label | test("<keyword>"; "i"))'
```

**NEVER calculate or aggregate metrics yourself if a pre-built metric exists.** The API provides pre-computed metrics that are more accurate and efficient than manual calculations.

**NEVER guess or fabricate metric IDs.** Always use the exact `metricId` UUIDs returned by the cached metadata. Hallucinated metric IDs will cause query failures.

### Step 2: Determine the Right Asset Level

Assets act as **aggregation points** (like SQL GROUP BY). Choose the appropriate asset:

| User asks about... | Query this asset | Filter by |
|--------------------|------------------|-----------|
| Organization/company-wide | `Team` | `Team.name = "Organization"` |
| A specific team's metrics | `Team` | `Team.name = "<team-name>"` (use `=`, NOT `DESCENDANT_OF`) |
| People in a team and sub-teams | `Person` | `Person.Teams.name` with `DESCENDANT_OF` operator |
| Metrics across a team tree | `Person` | `Person.Teams.name` with `DESCENDANT_OF` + metrics on `Person` |
| A specific person | `Person` or `PullRequest.Author` | Email or name |
| A specific repository | `Repository` or `PullRequest.Repository` | Repository name |
| Individual PRs/commits | `PullRequest` or `Commit` | As needed |
| Breakdown by dimension (tenure, job level, etc.) | Use `mode: "groups"` | See api-reference.md |

**IMPORTANT:** There is always a Team called "Organization" that represents the entire organization. For org-wide metrics, query `Team` filtered by `Team.name = "Organization"`. Do NOT manually aggregate across repositories or people.

#### Team Hierarchy: `=` vs `DESCENDANT_OF` vs `IN`

- **`=`** — Use for metrics on a single team. `Team.name = "Backend"` returns that team's aggregated metrics.
- **`DESCENDANT_OF`** — Use for **roster discovery only** (listing people). Expands a team to include all nested sub-teams. **Do NOT use `DESCENDANT_OF` for metric queries on `Team` — it causes double-counting** because parent team metrics already include sub-team data.
- **`IN`** — Use to query a specific set of teams by name.

**Correct pattern for metrics across a team tree:** Query `Person` (not `Team`) with `DESCENDANT_OF` on `Person.Teams.name`, then attach metrics to `Person`. Individual-level metrics don't double-count.

For additional patterns (top-level team discovery, manager lookups), see [references/api-reference.md](references/api-reference.md).

### Step 3: Use Pre-Aggregated Metrics

When using `granularity` in the time dimension, the API returns **already-aggregated values**. Do not perform additional aggregation on these results.

**Bad pattern (DO NOT DO THIS):**
1. Query individual PRs
2. Extract cycle times
3. Calculate average manually

**Good pattern (DO THIS):**
1. Query Team with `Team.name = "Organization"`
2. Include the cycle time metric
3. Use granularity for time series
4. Return the pre-aggregated results directly

**When comparing time periods**, always use the same asset, metric, and query path for both periods. Inconsistent query paths (e.g., different facades or aggregation levels) produce incomparable numbers.

### Step 4: Plan Multi-Step Queries

For complex queries requiring multiple API calls, use TaskCreate to track steps:

**Example: "Compare PR cycle time for top 5 teams over last 30 days"**
- Verify pr_cycle_time metric exists on Team asset
- Fetch teams sorted by PR volume, limit 5
- Get pr_cycle_time for each team with date filter
- Format and present results

Execute independent API calls in parallel, but limit to 2 concurrent calls maximum.

**Superlative queries** ("most", "least", "highest", "top N"): ensure you paginate through the full dataset. A query with `limit=25` may miss the actual top result if there are more than 25 rows.

## Querying the API

**Always use the query script.** Write the query JSON to a temp file, then execute:

```bash
cat > /tmp/span-query.json << 'EOF'
{
  "select": ["Team.name"],
  "filters": [{"field": "Team.name", "operator": "=", "value": "Organization"}],
  "metrics": [{"metricId": "<metric-id-from-cache>", "responseKey": "cycleTime"}],
  "timeDimension": {
    "timeRange": {"startTime": "2024-05-01", "endTime": "2024-06-01"},
    "granularity": "week"
  }
}
EOF
$SKILL_SCRIPTS/query.sh /tmp/span-query.json
```

For paginated results, pass limit and cursor: `$SKILL_SCRIPTS/query.sh /tmp/span-query.json 25 <cursor>`

See [references/api-reference.md](references/api-reference.md) for full request body format, filter operators, time dimensions, and groups mode.

## Formatting Results

**Always check `annotations` in the API response** for each metric's unit. The annotations tell you exactly how to interpret the raw values.

Possible units: `seconds`, `hours`, `days`, `usd`, `count`, `percentage_as_ratio`, `score`, `boolean`, `estimate`.

Convert accordingly:
- `seconds` → hours or days for display (e.g., `42483` seconds → "11.8 hours")
- `percentage_as_ratio` → multiply by 100 for display (e.g., `0.85` → "85%")
- `score` → display as-is (dimensionless score)
- `boolean` → display as Yes/No
- `estimate` → display as-is (story points or similar)

## Error Handling

**API Errors:**
- Metric unavailable on asset → "Metric X isn't available on Y. Available: [list]. Try [alternative]?"
- Empty results → "No data for [filters]. Try expanding time range or removing filters."
- Rate limits → Return partial results with note about limit reached

**Ambiguous Queries (see "Clarifying Questions" section above):**
- Missing time range → **Always ask.** Suggest 30 days as default option.
- Unclear entity → "Which team/service? Available: [list top options]"
- Unknown metric → "Metric not found. Did you mean: [similar metrics]?"

**Handle pagination** if `hasNextPage` is true in the response.

## Example Workflows by Domain

### Productivity
- **"How long does it take to merge PRs?"** → Query `Team` or `Person` with cycle time / time-to-merge metrics, weekly granularity
- **"Are we completing what we planned this sprint?"** → Query `Sprint` with planning accuracy, velocity, story point metrics
- **"How is the new hire ramping up?"** → Query `Person` filtered by name/email with PR throughput and review metrics over monthly granularity

### DORA
- **"How often are we deploying?"** → Query `Team` or `Service` with deployment frequency metric, weekly granularity
- **"What's our change failure rate?"** → Query `Service` or `Team` with change failure rate metric (incidents / deployments)
- **"What's our mean time to recovery?"** → Query `Team` with MTTR metric (check for avg, p50, p75, p90 variants)

### Investment
- **"Where is engineering effort going?"** → Query `Team` with FTE Days metric, filter by work type (features, maintenance, developer experience)
- **"How much effort is going into this epic?"** → Query `Epic` filtered by name with FTE Days metric
- **"What are our active workstreams?"** → Query `Team` with workstream-related metrics for effort breakdown

### AI Transformation
- **"Who is using AI tools?"** → Query `Team` or `Person` with AI adoption rate, active AI users metrics
- **"What percentage of code is AI-generated?"** → Query `Team` or `Person` with AI code ratio metric
- **"How much are we spending on AI?"** → Query `Team` with AI spend metrics (base + overage)

### Calendar
- **"How much time are engineers in meetings?"** → Query `Team` or `Person` with meeting hours, focus time metrics
- **"What's our maker time like?"** → Query `Team` with focus time and fragmented time metrics

### Administration
- **"Reload Span metadata"** → Run `$SKILL_SCRIPTS/fetch-metadata.sh`
- **"Reconfigure Span skill"** → Delete `$SPAN_DIR/auth.json` and re-run onboarding

For more detailed step-by-step walkthroughs, see [references/workflows.md](references/workflows.md).

For domain-specific query guidance (investment views, DORA facades, PR time dimensions, AI tool patterns, calendar caveats), see [references/domains.md](references/domains.md).

## Reference Material

- For API endpoint details, query parameters, time dimensions, and filters, see [references/api-reference.md](references/api-reference.md)
- For detailed step-by-step example workflows, see [references/workflows.md](references/workflows.md)
- For domain-specific knowledge and caveats, see [references/domains.md](references/domains.md)
