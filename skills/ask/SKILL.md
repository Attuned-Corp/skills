---
name: ask
description: Query engineering, project management, and investment data from the Span Knowledge Graph API. Includes pull requests, commits, deployments, epics, issues, sprints, investments, teams, and people.
allowed-tools: Read, Write, Bash(*), Grep, Glob
triggers:
  - PRs merged
  - pull requests
  - cycle time
  - engineering metrics
  - team velocity
  - code review time
  - deployment frequency
  - epics
  - issues
  - sprints
  - investments
  - project management
  - Span API
---

# Span Knowledge Graph API

This skill provides access to the Span Knowledge Graph API for querying engineering data.

## Clarifying Questions (IMPORTANT)

**Always ask clarifying questions rather than making assumptions.** This is especially important for:

### Time Intervals

If the user's query does not specify a time range, **always ask before executing**:

> "What time period would you like me to query? For example: last 30 days, last quarter, or a specific date range. (If you'd like, I can default to the last 30 days.)"

**Do NOT assume a time range.** Even if the query sounds like it implies "recent" data, ask explicitly.

Examples of queries that require clarification:
- "How many PRs did we merge?" → Ask for time range
- "What's our cycle time?" → Ask for time range
- "Show me deployment frequency" → Ask for time range

Examples where time range is provided (no need to ask):
- "PRs merged last week" → Use last 7 days
- "Cycle time for Q4" → Use Q4 date range
- "Deployments in January" → Use January date range

### Other Ambiguities

Also ask for clarification when:
- **Team/person is unclear**: "Which team would you like me to query?"
- **Metric is ambiguous**: "Did you mean X or Y metric?"
- **Scope is unclear**: "Should this be organization-wide or for a specific team?"

## Configuration Directory

The skill stores configuration in `~/.spanrc/` by default. To use a custom location, set the `SPAN_CONFIG_DIR` environment variable:

```bash
export SPAN_CONFIG_DIR="/path/to/custom/folder"
```

### Directory Structure

```
~/.spanrc/                    # or $SPAN_CONFIG_DIR
├── auth.json                 # Your Span Personal Access Token (required)
└── metadata-cache.json       # Cached API metadata (auto-generated)
```

## First-Time Setup (Onboarding)

On first invocation, check if the skill has been configured:

```bash
SPAN_DIR="${SPAN_CONFIG_DIR:-$HOME/.spanrc}"
jq -e '.token' "$SPAN_DIR/auth.json" > /dev/null 2>&1 && echo "configured" || echo "not configured"
```

### If Auth File Does Not Exist: Run Setup

If the auth file doesn't exist, the skill is not yet configured. You MUST run the onboarding flow before doing anything else:

1. **Create the configuration folder** if it doesn't exist:
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

3. **Verify the token file exists** and contains a valid token.

4. **Fetch initial metadata** and save to `$SPAN_DIR/metadata-cache.json`.

5. **Confirm setup is complete** and proceed with the user's original request.

## Configuration

The Personal Access Token (PAT) must be stored in `auth.json`:

```json
{
  "token": "your-personal-access-token"
}
```

## Token Security (CRITICAL)

**NEVER expose the Personal Access Token in any output.** Follow these rules strictly:

1. **Never use the Read tool** on `auth.json` - use `jq` with command substitution instead (see "Reading the Token" below)
2. **Never echo or print the token** - no `echo $TOKEN`, `printf`, or similar commands
3. **Never include the token in error messages** or explanations to the user

## Reading the Token

Use `jq` with command substitution directly in curl commands to keep the token secure:

```bash
SPAN_DIR="${SPAN_CONFIG_DIR:-$HOME/.spanrc}"
TOKEN=$(jq -r '.token' "$SPAN_DIR/auth.json")
```

## API Base URL

```
https://api.span.app
```

## Metadata Caching

The API metadata (assets, fields, metrics) is largely static and should be cached to avoid unnecessary API calls.

### Cache Location

Metadata is cached at `$SPAN_DIR/metadata-cache.json`.

### Cache Behavior

1. **On skill invocation**: Check if the cache file exists
   - If it exists, read and use the cached metadata instead of calling the API
   - If it does not exist, fetch metadata from the API and save it to the cache file

2. **To reload metadata**: Only fetch fresh metadata from the API when the user explicitly asks to "reload", "refresh", or "update" the Span metadata/definitions. Then update the cache file.

### Reading Cached Metadata

```bash
SPAN_DIR="${SPAN_CONFIG_DIR:-$HOME/.spanrc}"
cat "$SPAN_DIR/metadata-cache.json"
```

### Fetching and Caching Metadata

When cache doesn't exist or user requests a reload:

```bash
SPAN_DIR="${SPAN_CONFIG_DIR:-$HOME/.spanrc}"
TOKEN=$(jq -r '.token' "$SPAN_DIR/auth.json")
curl -s -X GET "https://api.span.app/next/metadata/assets" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" > "$SPAN_DIR/metadata-cache.json"
```

## Available Endpoints

### 1. Get Assets Metadata

Discover available assets, their fields, metrics, relations, and dimensions. **Note: Use cached metadata instead of calling this endpoint directly, unless explicitly refreshing.**

```bash
curl -s -X GET "https://api.span.app/next/metadata/assets" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

**Response includes:**
- Asset names (e.g., PullRequest, Person, Repository)
- Available fields for each asset
- Available metrics with IDs, labels, and descriptions
- Relations between assets
- Time dimensions

### 2. Get Metrics Metadata

Get detailed information about available metrics. **Note: This information is included in the assets metadata cache.**

```bash
curl -s -X GET "https://api.span.app/next/metadata/metrics" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

### 3. Query Assets

Query assets with filters, metrics, and time dimensions.

```bash
curl -s -X POST "https://api.span.app/next/assets/query" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "select": ["PullRequest.title", "PullRequest.Author.email", "PullRequest.Repository.name"],
    "filters": [
      {"field": "PullRequest.Author.email", "operator": "=", "value": "user@example.com"}
    ],
    "metrics": [
      {"metricId": "metric-uuid-here", "responseKey": "PullRequest.cycleTime"}
    ],
    "timeDimension": {
      "timeRange": {
        "startTime": "2024-05-01",
        "endTime": "2024-06-01"
      }
    },
    "order": {
      "field": "PullRequest.cycleTime",
      "direction": "desc"
    }
  }'
```

**Query Parameters:**
- `before` / `after`: Cursor-based pagination
- `limit`: Number of results (1-100, default 10)

**Request Body:**

| Field | Required | Description |
|-------|----------|-------------|
| `select` | Yes | Array of fields to return (e.g., `["PullRequest.title", "PullRequest.Author.email"]`) |
| `filters` | Yes | Array of filter conditions |
| `metrics` | Yes | Array of metrics to compute |
| `timeDimension` | No | Time range and optional granularity |
| `order` | No | Sort order for results |

**Filter Operators:**
- `=`, `!=`, `>`, `<`, `>=`, `<=`
- `IN`, `NOT IN`
- `contains`

**Time Granularity Options:**
- `day`, `week`, `month`, `quarter`, `year`

## Understanding Time Dimensions

The `timeDimension` field controls how the query scopes and aggregates data over time. It has two main components:

### Time Range (Required when using timeDimension)

The `timeRange` defines the window of data to query:

```json
"timeDimension": {
  "timeRange": {
    "startTime": "2024-05-01",
    "endTime": "2024-06-01"
  }
}
```

Use dates in `YYYY-MM-DD` format. The range is inclusive of both start and end dates.

### Granularity (Optional)

The `granularity` field determines whether results are returned as **individual records** or **aggregated time series**.

#### Without Granularity: Individual Records

When `granularity` is omitted, the query returns individual records that fall within the time range.

**Use this when:**
- Listing specific items (PRs, commits, deployments)
- Getting details about individual records
- The user asks "show me the PRs" or "list deployments"

**Example:** Get all PRs merged in May 2024
```json
{
  "select": ["PullRequest.title", "PullRequest.Author.email"],
  "filters": [{"field": "PullRequest.Repository.name", "operator": "=", "value": "myrepo"}],
  "metrics": [{"metricId": "cycle-time-uuid", "responseKey": "PullRequest.cycleTime"}],
  "timeDimension": {
    "timeRange": {"startTime": "2024-05-01", "endTime": "2024-05-31"}
  }
}
```

**Response format:**
```json
{
  "data": [
    {"PullRequest.title": "Fix bug", "PullRequest.Author.email": "dev@example.com", "PullRequest.cycleTime": 3600},
    {"PullRequest.title": "Add feature", "PullRequest.Author.email": "dev@example.com", "PullRequest.cycleTime": 7200}
  ]
}
```

#### With Granularity: Time Series Aggregation

When `granularity` is specified, metrics are aggregated into time buckets and returned as arrays of `{time, value}` pairs.

**Use this when:**
- Tracking trends over time
- Comparing periods (week over week, month over month)
- The user asks "how has X changed" or "show me the trend" or "weekly/monthly breakdown"

**Example:** Get weekly merged PR counts for a person
```json
{
  "select": ["Person.email"],
  "filters": [{"field": "Person.email", "operator": "=", "value": "dev@example.com"}],
  "metrics": [{"metricId": "merged-prs-uuid", "responseKey": "Person.totalMergedPRs"}],
  "timeDimension": {
    "timeRange": {"startTime": "2024-05-01", "endTime": "2024-06-01"},
    "granularity": "week"
  }
}
```

**Response format:**
```json
{
  "data": [
    {
      "Person.email": "dev@example.com",
      "Person.totalMergedPRs": [
        {"time": "2024-05-27T00:00:00.000Z", "value": 5},
        {"time": "2024-05-20T00:00:00.000Z", "value": 8},
        {"time": "2024-05-13T00:00:00.000Z", "value": 3}
      ]
    }
  ]
}
```

### Choosing the Right Granularity

| Granularity | Best For |
|-------------|----------|
| `day` | Short time ranges (1-2 weeks), daily standups |
| `week` | Sprint reviews, weekly reports (2-8 weeks) |
| `month` | Monthly reviews, quarterly planning (1-6 months) |
| `quarter` | Executive summaries, yearly reviews |
| `year` | Multi-year trends, historical analysis |

### Dimension Name (Advanced)

Some assets have multiple time dimensions (e.g., `createdAt`, `mergedAt`, `closedAt`). Use `dimensionName` to specify which one:

```json
"timeDimension": {
  "timeRange": {"startTime": "2024-05-01", "endTime": "2024-06-01"},
  "dimensionName": "mergedAt"
}
```

Check the metadata endpoint to see available dimensions for each asset.

## Organization-Level Queries

**IMPORTANT:** There is always a Team called "Organization" that represents the entire organization. When the user asks for organization-wide, company-wide, or aggregate metrics, query the Team asset filtered by `Team.name = "Organization"`.

**Example:** Get organization-wide PR cycle time:
```json
{
  "select": ["Team.name"],
  "filters": [{"field": "Team.name", "operator": "=", "value": "Organization"}],
  "metrics": [{"metricId": "<cycle-time-metric-id>", "responseKey": "cycleTime"}],
  "timeDimension": {
    "timeRange": {"startTime": "2024-05-01", "endTime": "2024-06-01"},
    "granularity": "week"
  }
}
```

This returns pre-aggregated metrics for the entire organization. Do NOT manually aggregate across repositories or people when org-level data is needed.

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

**ALWAYS inspect the cached metadata to find relevant metrics.** Search for metrics that match what the user is asking for:

```bash
# Search for metrics by keyword (e.g., "cycle", "time", "merged", "deploy")
SPAN_DIR="${SPAN_CONFIG_DIR:-$HOME/.spanrc}"
cat "$SPAN_DIR/metadata-cache.json" | jq '.data[].metrics[]? | select(.label | test("<keyword>"; "i"))'
```

**NEVER calculate or aggregate metrics yourself if a pre-built metric exists.** The API provides pre-computed metrics that are more accurate and efficient than manual calculations.

### Step 2: Determine the Right Asset Level

Assets act as **aggregation points** (like SQL GROUP BY). Teams have metrics aggregated for all members, Services have metrics aggregated for their codebase.

Choose the appropriate asset based on what the user is asking:

| User asks about... | Query this asset | Filter by |
|--------------------|------------------|-----------|
| Organization/company-wide | `Team` | `Team.name = "Organization"` |
| A specific team | `Team` | `Team.name = "<team-name>"` |
| A specific person | `Person` or `PullRequest.Author` | Email or name |
| A specific repository | `Repository` or `PullRequest.Repository` | Repository name |
| Individual PRs/commits | `PullRequest` or `Commit` | As needed |

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

### Step 4: Plan Multi-Step Queries

For complex queries requiring multiple API calls, use TodoWrite to track steps:

**Example: "Compare PR cycle time for top 5 teams over last 30 days"**
```
[TODO] Verify pr_cycle_time metric exists on Team asset
[TODO] Fetch teams sorted by PR volume, limit 5
[TODO] Get pr_cycle_time for each team with date filter
[TODO] Format and present results
```

**Example: "Find the engineer with slowest PR cycle time per team"**
```
[TODO] Fetch all teams (handle pagination if needed)
[TODO] For each team, fetch Person with cycle time metric, sorted desc, limit 1
[TODO] Present results with team and person details
```

Execute independent API calls in parallel, but limit to 2 concurrent calls maximum.

## Formatting Results

**Unit Conversions:**
- Time metrics are often in seconds—convert to hours/days for readability
- Example: `42483` seconds → "11.8 hours" or "0.49 days"

## Error Handling

**API Errors:**
- Metric unavailable on asset → "Metric X isn't available on Y. Available: [list]. Try [alternative]?"
- Empty results → "No data for [filters]. Try expanding time range or removing filters."
- Rate limits → Return partial results with note about limit reached

**Ambiguous Queries (see "Clarifying Questions" section above):**
- Missing time range → **Always ask.** Suggest 30 days as default option.
- Unclear entity → "Which team/service? Available: [list top options]"
- Unknown metric → "Metric not found. Did you mean: [similar metrics]?"

## Usage Instructions

1. **Check for skill configuration first**:
   - Determine config directory: `SPAN_DIR="${SPAN_CONFIG_DIR:-$HOME/.spanrc}"`
   - Look for `$SPAN_DIR/auth.json`
   - If it doesn't exist, run the onboarding flow (see "First-Time Setup" section)

2. **Check for cached metadata**:
   - Look for cache at `$SPAN_DIR/metadata-cache.json`
   - If it exists, read and use the cached data
   - If it doesn't exist, fetch from `/next/metadata/assets` and save to cache
   - Only refresh the cache when the user explicitly asks to reload/refresh metadata

3. **Plan your query (MANDATORY - see "Query Planning" section above)**:
   - Search metadata for applicable metrics
   - Determine the right asset level (Organization team for org-wide queries)
   - Use pre-aggregated metrics instead of manual calculations

4. **Build queries based on user needs:**
   - Select only the fields the user asks about
   - Apply appropriate filters
   - Include relevant metrics (use metric IDs from cached metadata)

5. **Return raw data** without analysis - let the user interpret the results.

6. **Handle pagination** if `hasNextPage` is true in the response.

## Example Workflows

### First-time user invokes the skill:

1. Determine config directory: `SPAN_DIR="${SPAN_CONFIG_DIR:-$HOME/.spanrc}"`
2. Check for `$SPAN_DIR/auth.json` - not found
3. Create the folder if needed
4. Prompt user to add their token to `auth.json`
5. Verify token exists
6. Fetch and cache metadata to `metadata-cache.json`
7. Proceed with user's original request

### Configured user asks "Show me PRs from the last month":

1. Load cached metadata from `$SPAN_DIR/metadata-cache.json`
2. Search metadata for relevant PR metrics (e.g., cycle time, PR size)
3. Query `PullRequest` asset with time dimension for last month
4. Convert time metrics to readable units, return results

### User asks "What's our org-wide PR cycle time for Q4?":

1. Load cached metadata from `$SPAN_DIR/metadata-cache.json`
2. Search for cycle time metric: `jq '.data[].metrics[]? | select(.label | test("cycle|time"; "i"))'`
3. Query `Team` filtered by `Team.name = "Organization"` with the metric
4. Use quarterly granularity in time dimension
5. Convert seconds to hours/days, return results

### User asks to "reload Span metadata" or "refresh Span definitions":

1. Fetch fresh metadata from `/next/metadata/assets`
2. Save to `$SPAN_DIR/metadata-cache.json` (overwriting existing cache)
3. Confirm the metadata has been refreshed

### User asks to "reconfigure Span skill" or "reset Span setup":

1. Delete `$SPAN_DIR/` folder (or just the auth.json)
2. Run the onboarding flow again
