# Issue Triage Agent - Feature Documentation

AI-powered GitHub issue quality assessment, enrichment, and triage for the BCApps repository.

## How it works

1. A user adds the `ai-triage` label to a GitHub issue
2. A GitHub Action triggers and runs the triage agent
3. **Phase 1** — Quality assessment: scores the issue across 5 dimensions (0-100)
4. **Phase 2** — Enrichment & triage: gathers context from code, ADO, Ideas Portal, and AppSource, then produces a triage recommendation
5. Results are published as a wiki page and (optionally) a compact comment on the issue
6. Labels are applied for triage status, priority, complexity, effort, implementation path, and team
7. The GitHub issue type is set (Bug / Feature / Task)

### Phase 2 gating

- **READY** (score ≥ 75): Proceeds to Phase 2
- **NEEDS WORK** (score 40-74): Proceeds to Phase 2 with a needs-info notice
- **INSUFFICIENT** (score < 40): Skips Phase 2, posts needs-info comment only

### What always runs (regardless of settings)

- Team label assignment (Finance / SCM / Integration)
- Issue type assignment (Bug / Feature / Task)
- Wiki report publishing

## Configuration

All settings are GitHub repository variables (Settings > Secrets and variables > Actions > Variables).

| Variable | Default | Description |
|----------|---------|-------------|
| `TRIAGE_REPO` | *(not set — uses source repo)* | Target repo for wiki reports. When set, reports go to that repo's wiki and only a brief comment is posted on the issue (no triage labels). When not set, full results are posted on the issue. |

### Secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `GITHUB_TOKEN` | Yes | Auto-provided by GitHub Actions |
| `COPILOT_API_KEY` | Yes | PAT with "Copilot Requests" permission for Copilot CLI |
| `ADO_PAT` | No | Azure DevOps PAT for work item search |

## Enrichment sources

| Source | Description |
|--------|-------------|
| **Repository code** | Reads AL files from the detected app area (up to 15KB), scored by keyword relevance |
| **Azure DevOps** | Searches Dynamics SMB ADO project for related work items (title + description), with relevance scoring and matched-keyword display |
| **Ideas Portal** | Fetches BC ideas from experience.dynamics.com, matched with fuzzy keyword matching and BC synonyms |
| **AppSource Marketplace** | Instructs the model to estimate ecosystem interest from its training knowledge; provides manual search URL |
| **Duplicate detection** | Compares against recent open issues using Jaccard similarity (≥ 35% overlap flagged) |

## Labels applied

### Triage status
| Label | Condition |
|-------|-----------|
| `triage/ready` | Quality score ≥ 75 |
| `triage/needs-info` | Quality score 40-74 |
| `triage/insufficient` | Quality score < 40 |

### Priority
| Label | Condition |
|-------|-----------|
| `priority/critical` | Priority score 9-10 |
| `priority/high` | Priority score 7-8 |
| `priority/medium` | Priority score 4-6 |
| `priority/low` | Priority score 1-3 |

### Complexity, Effort, Implementation Path
- `complexity/low`, `complexity/medium`, `complexity/high`
- `effort/xs-s`, `effort/m`, `effort/l-xl`
- `path/manual`, `path/copilot-assisted`, `path/agentic`

### Team (always applied)
- `Finance`, `SCM`, `Integration` — based on keyword scoring against the Dynamics SMB Ownership Matrix

### Issue type (always set via GraphQL)
- **Bug**, **Feature**, **Task** — mapped from Phase 1 classification (bug → Bug, feature/enhancement → Feature, question → Task)

## Wiki reports

Reports are published as wiki pages named `Triage-Report-Issue-{number}`. The report includes:

- **TL;DR** — verdict, scores, recommended action, and executive summary (visible without expanding)
- **Triage rationale** — collapsible: full 7-aspect assessment with rationales
- **Quality breakdown** — collapsible: 5-dimension score table with notes
- **Enrichment context** — collapsible: documentation, Ideas Portal, ADO work items, AppSource, community references
- **Source files analyzed** — collapsible: list of AL files used as context

Re-triaging an issue overwrites the wiki page (previous versions preserved in wiki git history).

## File manifest

All files that make up the triage agent. These need to be moved together when porting to another repository.

### GitHub Action workflow

| File | Purpose |
|------|---------|
| `.github/workflows/issue-triage.yml` | Workflow trigger, permissions, environment variables |

### Agent scripts (`.github/scripts/triage/`)

| File | Purpose |
|------|---------|
| `index.js` | Main orchestrator — coordinates all phases and applies results |
| `config.js` | Label definitions, score thresholds, app area keyword mappings, team ownership keywords, label/type mapping functions, cached directory detection |
| `models-client.js` | Copilot CLI wrapper — sends prompts via stdin, parses JSON responses, retry logic |
| `github-client.js` | GitHub REST/GraphQL client — issue fetching, comment posting (with retry), label management, issue type setting, re-triage detection with score extraction |
| `phase1-assess.js` | Phase 1 quality assessment — builds prompt from skill files, calls model, validates response with type coercion |
| `phase2-enrich.js` | Phase 2 enrichment & triage — builds prompt from skill files, fetches all enrichment in parallel, validates response, extracts key terms with BC domain phrases |
| `code-reader.js` | Reads AL source files from detected app area, scores by keyword relevance, caps at 15KB |
| `ado-client.js` | Azure DevOps WIQL search — title + description matching, relevance scoring with matched keywords, strips bracketed tags |
| `ideas-client.js` | Dynamics 365 Ideas Portal OData client — fuzzy matching with stemming and BC synonyms |
| `marketplace-client.js` | AppSource marketplace context — provides search terms and URL for model estimation |
| `duplicate-detector.js` | Jaccard similarity-based duplicate detection against recent open issues |
| `format-comment.js` | Issue comment formatter — compact format with wiki link, or verbose fallback if wiki unavailable |
| `format-report.js` | Wiki report formatter — TL;DR + collapsible detail sections |
| `wiki-client.js` | Wiki publisher — clones target wiki repo, writes page, commits, pushes. Target controlled by `TRIAGE_REPO` env var |
| `package.json` | Node.js project config, dependency on `@octokit/rest`, test script |

### Skill files (`plugins/triage/`)

The skill files are the **single source of truth** for triage domain knowledge. The agent reads them at runtime to build its prompts.

| File | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Plugin metadata |
| `skills/triage/SKILL.md` | Main skill — BC/AL domain glossary, triage process overview, routing to sub-files |
| `skills/triage/triage-assess.md` | Phase 1 knowledge — quality scoring rubric, verdict thresholds, issue improvement tips |
| `skills/triage/triage-enrich.md` | Phase 2 knowledge — triage criteria, priority formula, confidence calibration, recommended action logic, enrichment source descriptions |
| `skills/triage/triage-reference.md` | Reference data — app area keyword mappings, team ownership keywords, label definitions (documentation of what `config.js` implements) |

### Tests (`.github/scripts/triage/tests/`)

| File | Coverage |
|------|----------|
| `config.test.js` | App area detection, team labels, all label mapping functions, issue type mapping |
| `duplicate-detector.test.js` | Duplicate section formatting |
| `format-comment.test.js` | Compact + verbose comment formatting, wiki URL handling, re-triage diff |
| `format-report.test.js` | Wiki report structure, metadata, collapsible sections, re-triage diff |
| `wiki-client.test.js` | URL generation, TRIAGE_REPO override |

Run tests: `cd .github/scripts/triage && npm test`

### Dependencies

| Dependency | Installed via |
|------------|--------------|
| `@octokit/rest` | `npm ci` in `.github/scripts/triage/` |
| GitHub Copilot CLI | `npm install -g @github/copilot` in workflow |
| Node.js 20+ | `actions/setup-node@v4` in workflow |

## Porting to another repository

To move this agent to a different repository:

1. Copy `.github/workflows/issue-triage.yml`
2. Copy `.github/scripts/triage/` (entire directory including `node_modules/` lockfile)
3. Copy `plugins/triage/` (skill files — required, agent reads them at runtime)
4. Set up secrets: `COPILOT_API_KEY`, optionally `ADO_PAT`
5. Optionally set variable: `TRIAGE_REPO` (if reports should go to a separate wiki)
6. Create the first wiki page manually on the target repo (GitHub requires this before the Action can push)
7. Review `config.js` — app area mappings and team keywords may need adjustment for the new repo's directory structure

---

**Last Updated**: 2026-03-24
