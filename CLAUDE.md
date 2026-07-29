# CLAUDE.md

This repository contains portable agent skills for the Span Knowledge Graph
API. Keep every skill compatible with Claude Code, Codex, and Cursor.

## Repository Structure

- `skills/` - Available skills
- `.codex-plugin/` - Codex plugin metadata
- `.claude-plugin/` - Claude Code plugin and marketplace metadata
- Each skill has `SKILL.md` (the prompt) and `README.md` (documentation)

## Working with Skills

### Skill Format

Every `SKILL.md` must start with YAML frontmatter:

```yaml
---
name: skill-name
description: Brief description of what the skill does.
---
```

### When Creating or Modifying Skills

1. Ensure frontmatter is complete, valid, and useful for implicit activation
2. Avoid host-specific environment variables and prompt expansion unless a
   portable fallback is documented
3. Resolve bundled files relative to the selected `SKILL.md`, not the user's
   current working directory
4. Update the skill's README.md if behavior changes
5. Update the skills table in the root README.md if adding a new skill
6. Validate every changed skill with the Codex skill validator

### Naming

- Skill directories use kebab-case
- The `name` field in frontmatter must match the directory name
