# Issue Triage Agent - Feature documentation

Overview and pointers for the GitHub Issue Enrichment & Triage Agent feature.

## Key files

| File | Purpose |
|------|---------|
| `design.md` | Full PRD with requirements, architecture, and scoring rubrics |
| `tasks.md` | Implementation task list with phases and parallelization |

## Implementation

The implementation lives in `.github/scripts/triage/` - see `.github/scripts/triage/CLAUDE.md` for full details on the code structure, configuration, and usage instructions.

The GitHub Action workflow is at `.github/workflows/issue-triage.yml`.

## Test results (2026-03-11)

| Issue | Type | Score | Verdict | Key labels |
|-------|------|-------|---------|------------|
| #7 "Data Archive cleanup job..." | Sparse bug | 8/100 | INSUFFICIENT | `triage/insufficient` |
| #5 "Shopify Connector sync..." | Detailed bug | 92/100 | READY | `triage/ready`, `priority/high`, `path/copilot-assisted` |
| #6 "Copilot-assisted journal..." | Feature request | ~60/100 | NEEDS WORK | `triage/needs-info`, `complexity/high`, `path/manual` |

---

**Last Updated**: 2026-03-11 by jeschulz
