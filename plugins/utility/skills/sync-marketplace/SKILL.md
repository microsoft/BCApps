---
name: sync-marketplace
description: Scan plugins/ directory and update both marketplace JSON manifests to match what's on disk
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls *)
---

# Sync marketplace manifests

Scan the `plugins/` directory and update both marketplace JSON files to reflect the current state on disk.

## Marketplace files

- **Claude Code manifest**: `.claude-plugin/marketplace.json` - includes `author` field per plugin
- **Copilot manifest**: `.github/plugin/marketplace.json` - no `author` field per plugin

## Source of truth

The filesystem is the source of truth. Each plugin lives in `plugins/[plugin-name]/` with:

- `.claude-plugin/plugin.json` - plugin metadata (name, description, version, author, keywords)
- `commands/*.md` or `skills/[skill-name]/SKILL.md` - individual skill definitions

## Process

### Step 1: Discover plugins on disk

For each directory in `plugins/`:

1. Read `plugins/[name]/.claude-plugin/plugin.json` for metadata
2. List all skills by scanning `commands/*.md` and `skills/*/SKILL.md`
3. Record: name, description, version, category, tags/keywords, author, skill count

### Step 2: Read current manifests

1. Read `.claude-plugin/marketplace.json` (Claude Code)
2. Read `.github/plugin/marketplace.json` (Copilot)

### Step 3: Detect drift

Compare discovered plugins against both manifests. Look for:

- **New plugins** - directory exists on disk but not in manifests
- **Removed plugins** - entry in manifests but directory no longer exists
- **Changed metadata** - description, version, tags differ between plugin.json and manifests
- **New or removed skills** - skill files added or deleted since last sync

### Step 4: Update both manifests

For each plugin entry, populate from `plugin.json`:

- `name` - from plugin.json `name`
- `source` - `./plugins/[name]`
- `description` - from plugin.json `description`
- `version` - from plugin.json `version`
- `category` - from plugin.json `name` (or existing category if already set)
- `tags` - from plugin.json `keywords`
- `strict` - always `true`

**Claude Code manifest only** (`.claude-plugin/marketplace.json`):

- `author` - from plugin.json `author`

**Copilot manifest** (`.github/plugin/marketplace.json`):

- No `author` field per plugin

Preserve the top-level `name`, `owner`, and `metadata` fields from existing manifests.

### Step 5: Report changes

After updating, report what changed:

```markdown
## Sync results

### Added
- [list any new plugins or skills added]

### Removed
- [list any plugins or skills removed]

### Updated
- [list any metadata changes]

### No changes
- [list plugins that were already in sync]
```

## Rules

- Do NOT invent metadata - only use what's in `plugin.json` and skill files
- Preserve existing manifest structure (top-level name, owner, metadata)
- Keep plugins in the same order as they appear in existing manifests; append new plugins at the end
- Format JSON with 2-space indentation
- Both manifests must have identical plugin lists (same order, same data) except for the `author` field
