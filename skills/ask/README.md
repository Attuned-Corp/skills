# ask

Query and fetch data from the Span Knowledge Graph API.

## What it Does

This skill provides access to the Span Knowledge Graph API for querying:

**Engineering Data:**
- Pull requests, commits, deployments
- Repositories and services
- Engineering metrics (cycle time, throughput, etc.)

**Project Management:**
- Epics, issues, and sprints
- Project tracking and progress

**Investment & Planning:**
- Investment allocations and tracking

**People & Teams:**
- Team structures and members
- Individual contributor metrics

## Prerequisites

### Required Tools

The following command-line tools must be installed:

| Tool | Purpose | Installation |
|------|---------|--------------|
| `curl` | API requests | Usually pre-installed. If not: `brew install curl` (macOS) or `apt install curl` (Linux) |
| `jq` | JSON parsing | `brew install jq` (macOS) or `apt install jq` (Linux) |

### Authentication

You need a Span Personal Access Token. On first use, the skill will guide you through setup.

## Configuration

The skill stores configuration in `~/.spanrc/` by default:

```
~/.spanrc/
├── auth.json           # Your token (you create this)
└── metadata-cache.json # API metadata (auto-generated)
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

Invoke with `/span:ask` in Claude Code, or just ask questions naturally:

- "How many PRs did we merge last week?"
- "Show me the teams in Span"
- "What's the cycle time for the core team?"
- "Who merged the most PRs last month?"

## Automatic Activation

You don't need to invoke `/span:ask` every time. Claude will automatically use this skill when you ask questions about engineering metrics, PRs, teams, or repositories.

## Metadata Caching

The Span API metadata (available assets, fields, metrics) is cached locally after the first fetch:

- **First query**: Fetches and caches metadata, then runs your query
- **Subsequent queries**: Uses cached metadata (no extra API calls)

## Commands

| Command | What it does |
|---------|--------------|
| "Reload Span metadata" | Refreshes cached API metadata |
| "Reconfigure Span skill" | Resets configuration and runs setup again |
