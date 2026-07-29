# Span Skills

Skills for querying Span. Compatible with Codex, Claude Code, and Cursor.

## Available Skills

| Skill | Codex | Claude Code | Description |
|-------|-------|-------------|-------------|
| [ask](skills/ask/) | `$span:ask` | `/span:ask` | Query engineering metrics, team velocity, PRs, deployments, investments, and more |
| [env-readiness](skills/env-readiness/) | `$span:env-readiness` | `/span:env-readiness` | Investigate a repo's environment-readiness recommendations and print a prioritized, repo-grounded plan of which to implement and how |

## Installation

### Codex

#### Option 1: Marketplace (Recommended)

Install the Span plugin from the terminal:

```bash
codex plugin marketplace add Attuned-Corp/skills
codex plugin add span@span-skills
```

Codex opens a browser to authorize the bundled Span MCP server with OAuth.
No Personal Access Token is required for the Codex plugin.

#### Option 2: Clone and Symlink

Codex discovers standalone skills from `.agents/skills` directories and follows
symlinked skill folders:

```bash
git clone https://github.com/Attuned-Corp/skills.git ~/span-skills

# User-level (available in every repository)
mkdir -p ~/.agents/skills
ln -s ~/span-skills/skills/ask ~/.agents/skills/ask
ln -s ~/span-skills/skills/env-readiness ~/.agents/skills/env-readiness

# Or project-level (available only in the current repository)
mkdir -p .agents/skills
ln -s ~/span-skills/skills/ask .agents/skills/ask
ln -s ~/span-skills/skills/env-readiness .agents/skills/env-readiness
```

#### Verifying Installation

Run `codex plugin list` to verify a marketplace installation. For either
installation method, Codex detects skill changes automatically. If the skills
do not appear, restart Codex. Run `/skills` to browse installed skills, type
`$` to mention one explicitly, or ask a matching question and let Codex
activate it automatically.

This repository also includes a Codex plugin manifest for plugin-based
distribution and local marketplace testing.

#### Testing a Local Checkout

From this repository, register the checkout itself as a local marketplace and
install the plugin:

```bash
codex plugin marketplace add /absolute/path/to/skills
codex plugin add span@span-skills
codex plugin list
```

Restart Codex or open a new task, then run this smoke test:

```text
$span:ask What version is installed?
```

This verifies that Codex discovers the skill and can resolve its bundled
scripts without requiring a Span API query. Testing `$span:env-readiness` additionally
requires the Span MCP server.

After changing a locally installed skill, refresh the cached plugin and restart
Codex:

```bash
codex plugin remove span@span-skills
codex plugin add span@span-skills
```

If `span-skills` is already registered from another source, remove that
marketplace first with `codex plugin marketplace remove span-skills`, then add
the local checkout.

### Claude Code

#### Option 1: Marketplace (Recommended)

Install directly from within Claude Code:

```
/plugin marketplace add Attuned-Corp/skills
/plugin install span@span-skills
```

Or from the terminal:

```bash
claude plugin marketplace add Attuned-Corp/skills
claude plugin install span@span-skills
```

#### Option 2: Clone and Symlink

For local development or customization:

```bash
git clone https://github.com/Attuned-Corp/skills.git ~/span-plugin
ln -s ~/span-plugin ~/.claude/plugins/span
```

#### Option 3: Plugin Directory Flag

Load the plugin for a single session:

```bash
git clone https://github.com/Attuned-Corp/skills.git ~/span-plugin
claude --plugin-dir ~/span-plugin
```

#### Option 4: Git Submodule

For teams who want to pin a specific version:

```bash
git submodule add https://github.com/Attuned-Corp/skills.git vendor/span-plugin
claude --plugin-dir vendor/span-plugin
```

#### Verifying Installation

After installation, verify the plugin is loaded:

```
/plugin list
```

You should see `span` in the list of installed plugins.

### Cursor

Cursor natively supports skills using the same `SKILL.md` format. Clone the repo and symlink the skills into your project or user-level skills directory:

```bash
git clone https://github.com/Attuned-Corp/skills.git ~/span-skills

# Project-level (add to a specific project)
ln -s ~/span-skills/skills/ask .cursor/skills/ask

# Or user-level (available in all projects)
ln -s ~/span-skills/skills/ask ~/.cursor/skills/ask
```

For more details on how Cursor discovers and invokes skills or alternative methods of installation, see the [Cursor Skills documentation](https://cursor.com/docs/context/skills).

## Usage

### Direct Invocation

In Codex, type `$` followed by the skill name:

```
$span:ask
```

In Claude Code:

```
/span:ask
```

In Cursor, type `/` followed by the skill name in Agent chat:

```
/ask
```

### Natural Language (Automatic)

The AI agent automatically activates the skill when you ask relevant questions:

| You ask... | What happens |
|------------|--------------|
| "How many PRs did we merge last week?" | Queries PR count with time filter |
| "What's the cycle time for the core team?" | Fetches team cycle time metrics |
| "Who merged the most PRs last month?" | Ranks contributors by PR volume |
| "Show me deployment frequency trends" | Returns time-series deployment data |
| "Compare velocity across teams" | Aggregates metrics by team |

## Prerequisites

To use the Span skills, you need a [Span](https://span.app) account.

Codex plugin installations authenticate through OAuth. Claude Code, Cursor,
and standalone installations that do not expose the Span MCP server use a
Span Personal Access Token (PAT); the `ask` skill guides that fallback setup
on first use.

## Configuration

The `ask` skill stores fallback PAT configuration in `~/.spanrc/` by default:

```
~/.spanrc/
├── auth.json              # Your token (you create this)
├── metadata-cache.json    # API metadata (auto-generated)
└── api-version-detected   # API version from last metadata fetch (auto-generated)
```

To use a custom location, set the `SPAN_CONFIG_DIR` environment variable:

```bash
export SPAN_CONFIG_DIR="/path/to/custom/folder"
```

## About Span

[Span](https://span.app) is the AI-native engineering intelligence platform that brings clarity to engineering organizations. These skills bring Span's insights directly into your coding agent.

## License

MIT License - see [LICENSE](LICENSE) for details.
