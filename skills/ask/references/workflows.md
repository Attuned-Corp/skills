# Detailed Workflows

## First-time user invokes the skill

1. Configuration state shows "not configured"
2. Create the config folder: `mkdir -p "$SPAN_DIR"`
3. Prompt user to add their token to `$SPAN_DIR/auth.json`
4. Verify token exists
5. Run `$SKILL_SCRIPTS/fetch-metadata.sh`
6. Proceed with user's original request

## "Show me PRs from the last month"

1. Load cached metadata
2. Search for relevant PR metrics (cycle time, PR size, etc.)
3. Query `PullRequest` asset with time dimension for last month
4. Check response `annotations` for units, convert as needed
5. Return results

## "What's our org-wide PR cycle time for Q4?"

1. Search metadata for cycle time metric: `jq '.data[].metrics[]? | select(.label | test("cycle|time"; "i"))'`
2. Query `Team` filtered by `Team.name = "Organization"` with the metric
3. Use quarterly granularity
4. Convert seconds to hours/days, return results

## "Break down merged PRs by engineer tenure"

1. Search metadata for merged PRs metric on `Person` asset
2. Query with `mode: "groups"`, select `Person.personTenure`
3. Include the metric and a time range
4. Response returns one row per tenure bucket with aggregated metric values

## "Show me all engineers in the Platform team and sub-teams"

1. Query `Person` with filter: `{"field": "Person.Teams.name", "operator": "DESCENDANT_OF", "value": "Platform"}`
2. Select `Person.email`, `Person.Teams.name`
3. This expands "Platform" to include all nested sub-teams

## "Compare MTTR across services — show p90"

1. Search metadata for MTTR metric on `Service` asset
2. Query `Service` with the metric, specifying `"aggregationType": "p90"`
3. Add time dimension with appropriate range
4. Sort by metric descending to show worst-performing services first

## "Reload Span metadata"

1. Run `$SKILL_SCRIPTS/fetch-metadata.sh`
2. Confirm the metadata has been refreshed

## "Reconfigure Span skill"

1. Delete `$SPAN_DIR/auth.json`
2. Run the onboarding flow again
