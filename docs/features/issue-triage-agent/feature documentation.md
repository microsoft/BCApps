# Issue Triage Agent - Feature Documentation

AI-powered GitHub issue quality assessment, enrichment, and triage for the BCApps repository.

## How it works

1. A user adds the `ai-triage` label to a GitHub issue
2. A GitHub Action triggers and runs the triage agent
3. **Phase 1** — Quality assessment: scores the issue across 5 dimensions (0-100), extracts search terms
4. **Phase 2** — Enrichment & triage: gathers context from 11 sources in parallel, then runs 3 focused LLM calls (code analysis ∥ signal analysis → synthesis) to produce a triage recommendation
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
| `GITHUB_TOKEN` | Yes | Auto-provided by GitHub Actions (also used for PR search) |
| `COPILOT_API_KEY` | Yes | PAT with "Copilot Requests" permission for Copilot CLI |
| `ADO_PAT` | No | Azure DevOps PAT for work item search |
| `YOUTUBE_API_KEY` | No | YouTube Data API v3 key for video search |

## Enrichment sources

All sources are fetched in parallel for minimal latency.

| Source | Client | Description |
|--------|--------|-------------|
| **Repository code** | `code-reader.js` | Reads AL files from the detected app area (up to 15KB), scored by word-boundary keyword relevance |
| **Git history** | `git-history-client.js` | Analyzes last 3 months of commits in the app area: most-changed files, active contributors, keyword-matching commits |
| **Microsoft Learn** | `learn-client.js` | Live search of learn.microsoft.com API — provides real documentation URLs instead of LLM hallucination |
| **Azure DevOps** | `ado-client.js` | Full-text search via ADO Search API (primary) with WIQL fallback; relevance scoring with Jaccard similarity |
| **Ideas Portal** | `ideas-client.js` | OData `substringof()` queries on idea titles, sequential execution (`$top=10`), fuzzy matching with BC synonyms |
| **Pull requests** | `pr-client.js` | Searches GitHub PRs in the same repo — identifies in-progress (open) and recently addressed (merged) work |
| **Community forums** | `community-client.js` | Searches DynamicsUser.net Discourse API with staggered queries and 429 retry; results filtered by similarity and views |
| **YouTube** | `youtube-client.js` | Searches YouTube Data API v3 for BC tutorial/walkthrough videos as a demand signal |
| **Marketplace** | `marketplace-client.js` | LLM-assessed ecosystem density (Rich/Moderate/Sparse) with search URL for manual verification |
| **Duplicate detection** | `duplicate-detector.js` | Weighted Jaccard similarity (title-weighted 2:1) against recent open issues with BC synonym normalization |
| **Precedent finder** | `precedent-finder.js` | Finds similar closed issues for historical resolution context |

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
- **Enrichment context** — collapsible: Microsoft Learn articles, Ideas Portal, ADO work items, related PRs, Marketplace ecosystem, competitive landscape, community discussions, YouTube videos, code areas, git history
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
| `config.js` | Label definitions, score thresholds, app area keyword mappings, authoritative app-area-to-team map, label/type mapping functions |
| `models-client.js` | Copilot CLI wrapper — sends prompts via stdin, parses JSON responses, retry logic |
| `github-client.js` | GitHub REST/GraphQL client — issue fetching, comment posting (with retry), label management, issue type setting, re-triage detection with score extraction |
| `text-similarity.js` | Shared text similarity module — BC synonym normalization (35 groups), bigram extraction, Jaccard similarity, weighted title/body scoring |
| `phase1-assess.js` | Phase 1 quality assessment — loads prompt template from skill file, calls model, validates response with type coercion |
| `phase2-enrich.js` | Phase 2 enrichment & triage — 3-step LLM (code ∥ signal → synthesis), loads prompts from skill files, fetches 9 enrichment sources in parallel, regex fallback key term extraction |
| `code-reader.js` | Reads AL source files from detected app area, word-boundary keyword scoring, statSync pre-check, caps at 15KB |
| `git-history-client.js` | Git log analysis — change velocity (top 10 files), active contributors (top 5), keyword-matching commits |
| `learn-client.js` | Microsoft Learn API search — live BC documentation with real URLs, Jaccard similarity ranking |
| `ado-client.js` | Azure DevOps WIQL search — sanitized keywords, relevance scoring with Jaccard title similarity, active/closed split |
| `ideas-client.js` | Dynamics 365 Ideas Portal OData client — fuzzy matching with stemming, BC synonyms, early pagination exit |
| `pr-client.js` | GitHub PR search — open + merged PRs via search API, relevance scored with keyword matching and title similarity |
| `community-client.js` | DynamicsUser.net Discourse API search — staggered queries (1.2s delay), 429 retry with backoff, similarity/view filtering |
| `youtube-client.js` | YouTube Data API v3 search — BC video content as demand signal, requires `YOUTUBE_API_KEY` |
| `marketplace-client.js` | Marketplace ecosystem assessment — LLM-assessed density with search URL for verification |
| `duplicate-detector.js` | Weighted Jaccard duplicate detection — title-weighted 2:1, BC synonym normalization, 100-issue search window |
| `precedent-finder.js` | Similar closed issue finder — same weighted similarity, provides historical resolution context |
| `format-comment.js` | Issue comment formatter — compact format with wiki link, or verbose fallback if wiki unavailable |
| `format-report.js` | Wiki report formatter — TL;DR + collapsible details (Learn, Ideas, ADO, PRs, Marketplace, competitive landscape, community, YouTube, code, git history) |
| `wiki-client.js` | Wiki publisher — clones target wiki repo, writes page, commits, pushes. Target controlled by `TRIAGE_REPO` env var |
| `package.json` | Node.js project config, dependency on `@octokit/rest`, test script |

### Skill files (`plugins/triage/`)

The skill files are the **single source of truth** for triage domain knowledge. The agent reads them at runtime to build its prompts.

| File | Purpose |
|------|---------|
| `.claude-plugin/plugin.json` | Plugin metadata |
| `skills/triage/SKILL.md` | Main skill — BC/AL domain glossary, triage process overview, routing to sub-files |
| `skills/triage/bc-domain.md` | General BC functional domain knowledge (business processes, module relationships) |
| `skills/triage/triage-assess.md` | Phase 1 knowledge — quality scoring rubric, verdict thresholds, issue improvement tips |
| `skills/triage/triage-enrich.md` | Phase 2 knowledge — triage criteria, priority formula, confidence calibration, recommended action logic |
| `skills/triage/triage-reference.md` | Reference data — app area keyword mappings, team ownership keywords, label definitions |
| `skills/triage/phase1-instructions.md` | Phase 1 LLM system prompt template (with `{{placeholder}}` substitution) |
| `skills/triage/phase2-code-analysis.md` | Phase 2a LLM system prompt template (AL developer role — code analysis) |
| `skills/triage/phase2-signal-analysis.md` | Phase 2b LLM system prompt template (PM role — signal/value analysis) |
| `skills/triage/phase2-synthesis.md` | Phase 2c LLM system prompt template (PM role — synthesis) |
| `skills/triage/search-vocabulary.md` | BC domain phrases (70+) and stop words for regex fallback keyword extraction |
| `skills/triage/area-knowledge/*.md` | Area-specific domain knowledge (finance, sales, purchasing, inventory, warehouse, manufacturing, integration, e-document) |

### Tests (`.github/scripts/triage/tests/`)

63 tests across 6 test files:

| File | Coverage |
|------|----------|
| `config.test.js` | App area detection, authoritative team map, keyword fallback, all label mapping functions, issue type mapping |
| `duplicate-detector.test.js` | Duplicate section formatting |
| `format-comment.test.js` | Compact + verbose comment formatting, wiki URL handling, re-triage diff |
| `format-report.test.js` | Wiki report structure, metadata, collapsible sections, re-triage diff |
| `text-similarity.test.js` | Tokenization, BC synonym normalization, Jaccard similarity, weighted similarity |
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
4. Set up secrets: `COPILOT_API_KEY`, optionally `ADO_PAT` and `YOUTUBE_API_KEY`
5. Optionally set variable: `TRIAGE_REPO` (if reports should go to a separate wiki)
6. Create the first wiki page manually on the target repo (GitHub requires this before the Action can push)
7. Review `config.js` — app area mappings and team keywords may need adjustment for the new repo's directory structure

---

**Last Updated**: 2026-03-26
