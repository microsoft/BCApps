# Copilot Instructions: AI-First Repository

> **IMPORTANT**: This is the main instruction file. Load ALL referenced instruction files before proceeding with any task.

## Skills

Reusable skills (prompt-based commands) are located in the `/plugins` directory. Each plugin follows the structure `plugins/[plugin-name]/skills/[skill-name]/SKILL.md`. See `/plugins` for available skills and `.github/plugin/marketplace.json` for the full registry.

---

## 📚 Required Instruction Files

**BEFORE performing ANY task, you MUST load these files:**

| Order | File | Purpose |
|-------|------|----------|
| 1 | `.github/copilot/project-config.md` | **Config: Check feature toggles (ADO, Memory Bank, GitHub Projects)** |
| 2 | `.github/copilot/critical-evaluation.md` | Mindset: Challenge assumptions, disagree when necessary |
| 3 | `.github/copilot/task-workflow.md` | Process: Mandatory workflow for ALL tasks |
| 4 | `.github/copilot/code-guidelines.md` | Coding: Code surgery principles and quality standards |
| 5 | `.github/copilot/markdown-rules.md` | Formatting: Markdown standards (no em dashes, blank lines before lists) |
| 6 | `.github/copilot/memory-bank.md` | Context: Project memory (**only if Memory Bank = ✅ ON**) |

**🚨 MANDATORY**: If ANY of the first 5 files cannot be loaded, STOP immediately and inform the user.

---

## 🔧 Repository-Specific Rules

### Windows/PowerShell Environment
- **Starting servers**: Always check the terminal you are going to use - if you are running the front end web server, don't use the terminal for the back end!
- **Background processes**: Ensure proper handling for long-running tasks

### Documentation
- **Completion docs**: Create in `docs/<feature>/completion/` after completing tasks/features
- **DOCX conversion**: Use `scripts/md-to-docx.ps1`, place output with source MD file

### Developer Identity
- **Primary**: Read from `.developer` file in repo root (NAME= and EMAIL=)
- **Fallback**: Use Windows username from file paths if `.developer` doesn't exist
- **Usage**: "Last Updated by" fields, task completion attribution

---

## 🔄 Load Additional Files Based on project-config.md

**Check `.github/copilot/project-config.md` toggles first!**

**If Azure DevOps Integration = ✅ ON:**

- `.github/copilot/azure-devops-integration.md` - Feature-level tracking, ADO CLI commands
- `.github/copilot/ado-project-info.md` - ADO connection details (org, project, area path)

**If GitHub Projects = ✅ ON:**

- `.github/copilot/github-project-integration.md` - Issue creation, project board management

**Always available:**

- `.github/copilot/documentation-organization.md` - Directory structure, file placement rules

---

## 📖 Quick Reference

**Need guidance on...**

| Topic | See File |
|-------|----------|
| **Feature toggles (ADO/Memory Bank)** | **project-config.md** |
| How to think/respond | critical-evaluation.md |
| Task start/completion | task-workflow.md |
| Writing/modifying code | code-guidelines.md |
| Markdown formatting | markdown-rules.md |
| Doc file placement | documentation-organization.md |
| Azure DevOps sync | azure-devops-integration.md (if ADO = ON) |
| GitHub Projects sync | github-project-integration.md (if GitHub Projects = ON) |

**Detailed guidance index**: See `.github/copilot/README.md`

---

## ⚠️ CRITICAL Reminders

1. **Load project-config.md FIRST** to check feature toggles
2. **Load required files 2-5** before starting any work
3. **Load file 6 (Memory Bank) only if** Memory Bank = ✅ ON in project-config.md
4. **Follow task-workflow.md** for every task (before/during/after)
5. **Apply code-guidelines.md** for all code changes (surgical approach)
6. **Check markdown-rules.md** before editing any .md file
7. **Skip ADO references** if Azure DevOps Integration = ❌ OFF

---

**This file is an index only. All detailed guidance lives in the referenced files above.**
