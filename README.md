# Span Skills

Skills for querying engineering, project management, and investment data from the Span Knowledge Graph API. Compatible with Claude Code and Cursor.

## Available Skills

| Skill | Command | Description |
|-------|---------|-------------|
| [ask](skills/ask/) | `/span:ask` | Query engineering, project management, and investment data |

**Triggers:** PRs, cycle time, deployments, epics, issues, sprints, investments, teams

## Installation

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

To use the span plugin, you need:

1. A [Span](https://span.app) account
2. A Personal Access Token (PAT) from Span

On first use, the skill will guide you through configuration.

## Configuration

The plugin stores configuration in `~/.spanrc/` by default:

```
~/.spanrc/
├── auth.json           # Your token (you create this)
└── metadata-cache.json # API metadata (auto-generated)
```

To use a custom location, set the `SPAN_CONFIG_DIR` environment variable:

```bash
export SPAN_CONFIG_DIR="/path/to/custom/folder"
```

## About Span

[Span](https://span.app) is the AI-native engineering intelligence platform that brings clarity to engineering organizations. This plugin brings Span's insights directly into your terminal.

## License

MIT License - see [LICENSE](LICENSE) for details.
