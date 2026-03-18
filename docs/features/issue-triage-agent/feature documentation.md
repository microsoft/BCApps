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

### Key changes (2026-03-17)

- **Copilot CLI**: Model inference now uses GitHub Copilot CLI (`copilot -p`) instead of the GitHub Models REST API. Auth via `COPILOT_GITHUB_TOKEN` PAT with "Copilot Requests" permission.
- **Phase 2 gating**: Phase 2 (enrichment & triage) runs for both READY (score >= 75) and NEEDS WORK (score 40-74) issues. Only INSUFFICIENT issues (score < 40) get a needs-info comment and skip Phase 2.
- **Broader code search**: App area detection covers all of `src/` (Business Foundation, System Application, Tools) not just `src/Apps/W1/`.
- **Team assignment**: Issues are automatically assigned to **Finance**, **SCM**, or **Integration** teams via labels, based on keyword matching against the Dynamics SMB Ownership Matrix.
- **ADO query optimization**: WIQL queries use OR logic on title-only with 3 keywords max, avoiding 408 timeouts on the large Dynamics SMB project.

## Test results (2026-03-11)

| Issue | Type | Score | Verdict | Key labels |
|-------|------|-------|---------|------------|
| #7 "Data Archive cleanup job..." | Sparse bug | 8/100 | INSUFFICIENT | `triage/insufficient` |
| #5 "Shopify Connector sync..." | Detailed bug | 92/100 | READY | `triage/ready`, `priority/high`, `path/copilot-assisted` |
| #6 "Copilot-assisted journal..." | Feature request | ~60/100 | NEEDS WORK | `triage/needs-info`, `complexity/high`, `path/manual` |

---

**Last Updated**: 2026-03-17 by jeschulz
