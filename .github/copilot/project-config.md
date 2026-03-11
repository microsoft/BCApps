# Project Configuration

> **Purpose**: Toggle optional features for this repository. All prompts and copilot files check this configuration.

---

## Feature Toggles

| Feature | Status | Description |
|---------|--------|-------------|
| **Azure DevOps Integration** | ❌ OFF | ADO Feature tracking, work item links, SOA prefixes |
| **Memory Bank** | ❌ OFF | Context persistence across sessions |
| **GitHub Projects** | ❌ OFF | Issue creation, project board sync |

---

## How to Enable/Disable

Change the status in the table above:

- `✅ ON` - Feature is enabled
- `❌ OFF` - Feature is disabled

---

## What Each Toggle Controls

### Azure DevOps Integration (❌ OFF)

**When ON:**

- Phase headers include ADO Feature work item links
- Task titles use "SOA Phase X:" prefix
- AI syncs progress to ADO automatically
- Requires `.github/copilot/ado-project-info.md` configuration

**When OFF:**

- No ADO references in tasks
- No SOA prefixes
- No work item links
- Simpler task format without ADO metadata

### Memory Bank (❌ OFF)

**When ON:**

- Load `.github/copilot/memory-bank.md` at session start
- Maintain context across conversations
- Update memory bank with project decisions

**When OFF:**

- Skip memory bank loading
- Each session starts fresh
- No persistent context management

### GitHub Projects (❌ OFF)

**When ON:**

- Create GitHub Issues for phases/tasks
- Sync to GitHub Project board
- Track progress via issue state

**When OFF:**

- No GitHub Issues created
- No project board integration
- Track progress only in TASKS.md

---

## Developer Identity

For "Last Updated by" and task completion attribution, the AI checks:

1. **`.developer` file** (add to .gitignore, per-developer) - Primary source
2. **Windows username** - Fallback if `.developer` doesn't exist

### Setting Up Your Identity

Create a `.developer` file in the repo root (add to `.gitignore`):

```
NAME=Your Full Name
EMAIL=your.email@example.com
```

**Example:**

```
NAME=Greg Ratajik
EMAIL=Greg.Ratajik@microsoft.com
```

If this file doesn't exist, the AI will use the Windows username from file paths.

---

## Quick Setup

### Minimal Setup (all features off)

Leave all toggles as ❌ OFF. Tasks will use simple format:

```markdown
## Phase 1: Setup

- [ ] 1.1 Create project structure
- [ ] 1.2 Configure dependencies
```

### Full Enterprise Setup (all features on)

Set all toggles to ✅ ON and configure:

1. `.github/copilot/ado-project-info.md` - ADO connection details
2. `.github/copilot/memory-bank.md` - Memory bank rules
3. GitHub CLI authenticated with project scope

---

**Last Updated:** December 3, 2025 by gregrata
