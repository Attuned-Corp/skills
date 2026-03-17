# Span API Reference

## API Base URL

```
https://api.span.app
```

## Field Path Notation

Fields use dot notation to traverse relations between assets:

- `PullRequest.title` — direct field on PullRequest
- `PullRequest.Author.email` — traverses the Author relation to get email
- `Person.Teams.groupId` — traverses the Teams relation to get groupId

Any asset can also be filtered by its implicit `id` field (e.g., `PullRequest.id`).

## Available Endpoints

### 1. Get Assets Metadata

Discover available assets, their fields, metrics, relations, and dimensions. **Use cached metadata instead of calling this directly, unless refreshing.**

```bash
curl -s -X GET "https://api.span.app/next/metadata/assets" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

**Response includes per asset:**
- `fields` — available fields (name, type, nested sub-fields)
- `metrics` — available metrics with IDs, labels, descriptions, units, and supported aggregation types
- `relations` — connections to other assets (name and target type)
- `dimensions` — available time dimensions (name, label, description)

### 2. Get Metrics Metadata

Get detailed metric information. **This is included in the assets metadata cache.**

```bash
curl -s -X GET "https://api.span.app/next/metadata/metrics" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

### 3. Query Assets

Query assets with filters, metrics, and time dimensions.

```bash
curl -s -X POST "https://api.span.app/next/assets/query?limit=25" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "select": ["PullRequest.title", "PullRequest.Author.email"],
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

**Query Parameters (URL):**
- `limit`: Number of results (1-100, default 25)
- `after`: Cursor for next page (from `meta.page.endCursor` in response)

**Request Body:**

| Field | Required | Description |
|-------|----------|-------------|
| `select` | Yes | Array of field paths to return (dot notation) |
| `filters` | No (default `[]`) | Array of filter conditions. Must be present, can be empty. |
| `metrics` | No (default `[]`) | Array of metrics to compute. Must be present, can be empty. |
| `timeDimension` | No | Time range and optional granularity |
| `order` | No | Sort order (`field` + `direction`: `"asc"` or `"desc"`) |
| `mode` | No | `"groups"` for dimension-based aggregation (see Groups Mode below) |

### Metric Object

Each metric in the `metrics` array:

| Field | Required | Description |
|-------|----------|-------------|
| `metricId` | Yes | UUID from cached metadata |
| `responseKey` | No | Key name in the response data |
| `aggregationType` | No | One of: `avg`, `max`, `p50`, `p75`, `p90`. Defaults to the metric's default aggregation. |

### Filter Operators

| Operator | Description |
|----------|-------------|
| `=`, `!=`, `>`, `<`, `>=`, `<=` | Standard comparison |
| `IN`, `NOT IN` | List membership (value is an array) |
| `CONTAINS`, `NOT_CONTAINS` | Substring / field matching (**catalog fields only** — see note below) |
| `DESCENDANT_OF` | Hierarchical tree traversal — expands a team and all its sub-teams (**roster discovery only**, see warning below) |

**CONTAINS / NOT_CONTAINS constraints:** These operators only work on catalog fields (e.g., `Repository.repositoryName`, `Team.path`, `PullRequest.title`). They are NOT supported on dimension or relation fields (e.g., `Person.Teams.name`). Use `=` or `IN` for those instead.

**Compound filters** — use `"and"` to combine multiple conditions:
```json
{"and": [
  {"field": "Person.Teams.name", "operator": "=", "value": "Backend"},
  {"field": "Person.email", "operator": "CONTAINS", "value": "@example.com"}
]}
```

**DESCENDANT_OF — roster discovery only:**

`DESCENDANT_OF` expands a team to include all nested sub-teams. Use it to discover **people** in a team tree:
```json
{"field": "Person.Teams.name", "operator": "DESCENDANT_OF", "value": "Engineering"}
```

**WARNING:** Do NOT use `DESCENDANT_OF` for metric queries on `Team`. Parent team metrics already include sub-team data, so `DESCENDANT_OF` would cause double-counting. For metrics across a team hierarchy, query `Person` with `DESCENDANT_OF` on `Person.Teams.name` and attach metrics to individual people.

**Finding top-level teams:**
```json
{"field": "Team.path", "operator": "NOT_CONTAINS", "value": "."}
```
This returns only root teams (teams whose path has no `.` separator, meaning they are not nested under another team).

**Manager lookups:** Use the `Person.Manager` relation to find a person's manager:
```json
{"select": ["Person.email", "Person.Manager.email"]}
```

## Response Shape

```json
{
  "data": [
    {"PullRequest.title": "Fix bug", "PullRequest.cycleTime": 3600}
  ],
  "meta": {
    "page": {
      "endCursor": "opaque-cursor-string",
      "startCursor": "opaque-cursor-string",
      "hasNextPage": true,
      "hasPreviousPage": false,
      "pageSize": 25
    },
    "total": 142
  },
  "annotations": {
    "PullRequest.cycleTime": {
      "metricId": "metric-uuid",
      "unit": "seconds"
    }
  }
}
```

**Pagination:** If `meta.page.hasNextPage` is `true`, pass `meta.page.endCursor` as the `after` query parameter to get the next page.

**Units in annotations:** Common values are `seconds`, `hours`, `days`, `usd`, `count`, `percentage_as_ratio`, `score`, `boolean`, `estimate`. Use these to format results correctly.

## Time Dimensions

The `timeDimension` field scopes and aggregates data over time.

### Time Range

```json
"timeDimension": {
  "timeRange": {"startTime": "2024-05-01", "endTime": "2024-06-01"}
}
```

Dates use `YYYY-MM-DD` format. Range is inclusive. If `granularity` is present, `timeRange` is required.

### Granularity

Without granularity: returns individual records. With granularity: returns metrics as `[{time, value}, ...]` time series arrays.

| Granularity | Best For |
|-------------|----------|
| `day` | Short ranges (1-2 weeks), daily standups |
| `week` | Sprint reviews, weekly reports (2-8 weeks) |
| `month` | Monthly reviews, quarterly planning (1-6 months) |
| `quarter` | Executive summaries, yearly reviews |
| `year` | Multi-year trends |

**Example — individual records (no granularity):**
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

Response: `{"data": [{"PullRequest.title": "Fix bug", "PullRequest.cycleTime": 3600}, ...]}`

**Example — time series (with granularity):**
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

Response: metrics become arrays of `{time, value}` pairs:
```json
{"data": [{"Person.email": "dev@example.com", "Person.totalMergedPRs": [
  {"time": "2024-05-27T00:00:00.000Z", "value": 5},
  {"time": "2024-05-20T00:00:00.000Z", "value": 8}
]}]}
```

### Dimension Name

Assets can have multiple time dimensions. Use `dimensionName` to specify which one:

| Asset | Available Dimensions |
|-------|---------------------|
| PullRequest | `ts` only — there is NO `mergedAt` or `createdAt` dimension. To filter by merge date, use the `extMergedAt` catalog field in filters, not `dimensionName`. |
| Issue, Epic | `ts`, `issueCreatedAt`, `issueAssetUpdatedAt` |
| Others | Check metadata `dimensions` array |

```json
"timeDimension": {
  "timeRange": {"startTime": "2024-05-01", "endTime": "2024-06-01"},
  "dimensionName": "issueCreatedAt"
}
```

## Groups Mode

Set `"mode": "groups"` to aggregate metrics by dimension values (e.g., tenure, job level, investment type) instead of individual asset rows.

**Constraints:**
- `select` must contain only dimension fields
- At least one metric required
- No ordering
- No pagination

```json
{
  "select": ["Person.personTenure"],
  "filters": [],
  "metrics": [{"metricId": "merged-prs-uuid", "responseKey": "totalMergedPRs"}],
  "mode": "groups",
  "timeDimension": {
    "timeRange": {"startTime": "2024-05-01", "endTime": "2024-06-01"}
  }
}
```

Response:
```json
{"data": [
  {"Person.personTenure": "2y+", "totalMergedPRs": 3129},
  {"Person.personTenure": "1y", "totalMergedPRs": 1855},
  {"Person.personTenure": "6m", "totalMergedPRs": 412}
]}
```

With granularity, metrics become `[{time, value}, ...]` arrays as usual.

## Organization-Level Queries

There is always a Team called "Organization" that represents the entire org. For company-wide metrics, query `Team` filtered by `Team.name = "Organization"`:

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

Do NOT manually aggregate across repositories or people when org-level data is needed.
