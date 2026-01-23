# CLAUDE.md

This repository contains Claude Code skills for the Span Knowledge Graph API.

## Repository Structure

- `skills/` - Available skills
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

1. Ensure frontmatter is complete and valid
2. Update the skill's README.md if behavior changes
3. Update the skills table in the root README.md if adding a new skill

### Naming

- Skill directories use kebab-case
- The `name` field in frontmatter must match the directory name
