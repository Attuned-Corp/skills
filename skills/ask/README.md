# ask

Query Span for organizational observability.

## What it Does

This skill queries Span across five domains:

- **Productivity** — cycle time, throughput, review metrics, onboarding
- **DORA** — deployment frequency, lead time, MTTR, change failure rate
- **Investment** — effort allocation, workstreams, cost capitalization
- **AI Transformation** — AI code ratio, adoption rates, spend
- **Calendar** — focus time, meeting load, maker time

## Prerequisites

Codex plugin installations use the bundled Span MCP server and authenticate
through OAuth in the browser. They do not require a Personal Access Token or
the command-line tools below.

### API Script Fallback Tools

The following command-line tools must be installed:

| Tool | Purpose | Installation |
|------|---------|--------------|
| `curl` | API requests | Usually pre-installed. If not: `brew install curl` (macOS) or `apt install curl` (Linux) |
| `jq` | JSON parsing | `brew install jq` (macOS) or `apt install jq` (Linux) |

### API Script Fallback Authentication

Claude Code, Cursor, and standalone installations without the Span MCP server
need a Span Personal Access Token. On first use, the skill guides that fallback
setup.

## Skill Structure

```
ask/
├── SKILL.md                          # Core skill prompt
├── README.md
├── scripts/
│   ├── check-config.sh               # Configuration & version check
│   ├── check-version.sh              # Skill version check (compares local vs GitHub)
│   ├── fetch-metadata.sh             # Metadata fetch & caching
│   ├── query.sh                      # API query wrapper
│   └── api-version                   # Expected API version (empty = pre-versioning)
└── references/
    ├── api-reference.md              # Full API endpoint docs, filters, time dimensions
    ├── workflows.md                  # Step-by-step query examples
    └── domains.md                    # Domain-specific caveats & patterns
```

## Configuration

The API script fallback stores configuration in `~/.spanrc/` by default:

```
~/.spanrc/
├── auth.json              # Your token (you create this)
├── metadata-cache.json    # API metadata (auto-generated)
└── api-version-detected   # API version from last metadata fetch (auto-generated)
```

### File Permissions

The auth file contains your personal access token. Set restrictive permissions to prevent other users from reading it:

```bash
chmod 600 ~/.spanrc/auth.json
```

### Custom Location

To use a different folder, set the `SPAN_CONFIG_DIR` environment variable:

```bash
export SPAN_CONFIG_DIR="/path/to/custom/folder"
```

## Usage

Invoke with `$span:ask` in Codex, `/span:ask` in Claude Code, or just ask questions
naturally:

- "How many PRs did we merge last week?"
- "Show me the teams in Span"
- "What's the cycle time for the core team?"
- "Who merged the most PRs last month?"

## Automatic Activation

You don't need to invoke the skill every time. Codex, Claude Code, and Cursor
can automatically use it when you ask questions about engineering metrics,
PRs, teams, or repositories.

## Metadata Caching

The Span API metadata (available assets, fields, metrics) is cached locally after the first fetch:

- **First query**: Fetches and caches metadata, then runs your query
- **Subsequent queries**: Uses cached metadata (no extra API calls)

## API Compatibility

The skill checks for API version changes on each invocation. If the Span API introduces a new version that the skill doesn't recognize, you'll see a warning prompting you to update the skill.

## Commands

| Command | What it does |
|---------|--------------|
| "What version is installed?" | Shows installed version and checks GitHub for updates |
| "Reload Span metadata" | Refreshes cached API metadata |
| "Reconfigure Span skill" | Resets configuration and runs setup again |
