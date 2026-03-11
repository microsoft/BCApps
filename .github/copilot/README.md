# Copilot Instructions Directory

This directory contains all Copilot behavior guidelines and workflow instructions for the AI-First repository. It is meant to be ref'd from copilot-instructions.md 

## 📚 Core Instruction Files

These files define how Copilot should behave when working in this repository:

### Essential Files (Load Always)

| File | Purpose | When to Use |
|------|---------|-------------|
| **critical-evaluation.md** | Guidelines for honest, critical responses | Always - Foundational mindset |
| **task-workflow.md** | Complete workflow for task management | Before/after every task |
| **code-guidelines.md** | Code surgery principles and standards | When writing/modifying code |
| **markdown-rules.md** | Markdown formatting standards | When creating/editing markdown |

### Integration Files (Load as Needed)

| File | Purpose | When to Use |
|------|---------|-------------|
| **azure-devops-integration.md** | ADO Feature-level tracking rules | When syncing with Azure DevOps |
| **github-project-integration.md** | GitHub Projects board management | When using GitHub Projects |
| **documentation-organization.md** | Doc structure and placement rules | When creating/organizing docs |

---

## 🔄 Typical Workflows

### Starting Any Task

1. Load: `task-workflow.md` (mandatory)
2. Load: `critical-evaluation.md` (mindset)
3. Read: Project's `TASKS.md` and `design.md`
4. Load integration file if using ADO or GitHub Projects
5. Begin work following code-guidelines.md

### Writing Code

1. Follow: `code-guidelines.md` (surgical approach)
2. Apply: Repository-specific style
3. Test: Minimally but appropriately
4. Document: When needed

### Creating Documentation

1. Follow: `markdown-rules.md` (formatting)
2. Consult: `documentation-organization.md` (placement)
3. Cross-reference: Related docs
4. Update: `TASKS.md` and `design.md`

### Completing a Task

1. Follow: `task-workflow.md` completion checklist
2. Update: `TASKS.md` with completion info
3. Create: Completion doc if significant work
4. Sync: ADO or GitHub Projects (automatic)

---

## 📖 File Details

### critical-evaluation.md
**Purpose:** Establish mindset for honest, critical responses

**Key principles:**
- Question assumptions
- Disagree when necessary
- Acknowledge uncertainty
- Provide balanced perspectives

**When to apply:** All interactions, especially when reviewing designs or evaluating approaches

---

### task-workflow.md
**Purpose:** Define mandatory workflow for all task work

**Covers:**
- Pre-task documentation review
- Context gathering patterns
- Task completion checklist
- Documentation requirements
- ADO/GitHub sync procedures

**Critical sections:**
- 🚨 BEFORE Starting Any Task
- 🚨 AFTER Completing Any Task
- Documentation discovery patterns

---

### code-guidelines.md
**Purpose:** Define code surgery principles and quality standards

**Key concepts:**
- Surgical approach (smallest diff)
- Hard rules (never violate)
- Scope and budget guidelines
- Stability contract
- Testing philosophy

**When to apply:** Any code modification or creation

---

### markdown-rules.md
**Purpose:** Ensure consistent, convertible markdown

**Critical rules:**
- No em dashes (use `-` or `--`)
- Blank lines before lists
- Consistent formatting
- DOCX conversion considerations

**When to apply:** Creating or editing any `.md` file

---

### azure-devops-integration.md
**Purpose:** Rules for syncing with Azure DevOps

**Covers:**
- Feature-level tracking (not individual tasks)
- Compact HTML descriptions
- PowerShell commands for ADO CLI
- Status synchronization

**When to use:** Projects using Azure DevOps for tracking

---

### github-project-integration.md
**Purpose:** Rules for syncing with GitHub Projects

**Covers:**
- Issue creation from tasks
- Project board management
- Status transitions
- Quick workflow scripts

**When to use:** Projects using GitHub Projects for tracking

---

### documentation-organization.md
**Purpose:** Define documentation structure and placement

**Key sections:**
- Directory structure rules
- File placement guidelines
- Documentation categories
- Hierarchical documentation

**Critical rule:** Never create docs in root `docs/` - always use appropriate subdirectory

---

## 🎯 Quick Reference

### Most Important Rules

1. **Code Surgery:** Make the smallest change that solves the problem
2. **Task Workflow:** Always read docs BEFORE starting, update docs AFTER completing
3. **Critical Thinking:** Challenge assumptions, disagree when necessary
4. **Markdown:** No em dashes, blank lines before lists
5. **Documentation:** Place in correct subdirectory, never in root

---

## 🚫 Common Mistakes to Avoid

### Code
- ❌ Reformatting unrelated code
- ❌ Sweeping refactors
- ❌ Breaking backward compatibility
- ❌ Touching unrelated tests

### Tasks
- ❌ Starting without reading existing docs
- ❌ Completing without updating TASKS.md
- ❌ Creating duplicate documentation
- ❌ Ignoring established patterns

### Documentation
- ❌ Using em dashes in markdown
- ❌ Missing blank lines before lists
- ❌ Placing docs in wrong directory
- ❌ Breaking cross-references

---

## 🔄 Relationship to copilot-instructions.md

The main `copilot-instructions.md` file (in `.github/`) references these detailed guidelines:

```
copilot-instructions.md (overview)
    ├── critical-evaluation.md (mindset)
    ├── task-workflow.md (process)
    ├── code-guidelines.md (coding)
    ├── markdown-rules.md (formatting)
    └── integration files (syncing)
```

**Load order:**
1. Main instructions first (copilot-instructions.md)
2. Core files always (critical-evaluation, task-workflow, code-guidelines, markdown-rules)
3. Integration files as needed (azure-devops, github-project, documentation-organization)

---

## 🔍 Finding the Right File

**I need to know...**

| ...how to... | Read this file |
|-------------|----------------|
| Think critically and disagree | critical-evaluation.md |
| Start/complete a task | task-workflow.md |
| Write/modify code | code-guidelines.md |
| Format markdown | markdown-rules.md |
| Sync with Azure DevOps | azure-devops-integration.md |
| Sync with GitHub Projects | github-project-integration.md |
| Organize documentation | documentation-organization.md |

---

## 📝 Maintenance

### When to Update These Files

- New patterns emerge in the project
- Common mistakes need to be prevented
- Integration requirements change
- Team practices evolve

### How to Update

1. Identify duplication across files
2. Consolidate into appropriate file
3. Update cross-references
4. Test with actual Copilot session
5. Document changes in git commit

---

## Version

**Last Updated:** November 2025  
**Maintained by:** AI-First Repository Contributors  
**Status:** Active - These guidelines are enforced
