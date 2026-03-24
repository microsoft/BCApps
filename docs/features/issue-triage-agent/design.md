# GitHub Issue Enrichment & Triage Agent - Design Document

> **Feature**: AI-powered GitHub issue quality assessment, enrichment, and triage
> **Trigger**: Adding the `ai-triage` label to a GitHub issue
> **Runtime**: GitHub Action + GitHub Copilot CLI (`copilot -p`)
> **Last Updated**: 2026-03-17 by jeschulz

---

## 1. Introduction/Overview

Product managers on the BCApps repository receive GitHub issues ranging from sparse one-liners ("bug in data archive") to detailed reports with reproduction steps, environment info, and expected/actual behavior. Today, triaging these issues requires significant manual effort:

- Reading and interpreting the issue
- Researching related documentation, known issues, and community discussions
- Assessing complexity and estimating effort
- Determining the best implementation path (manual, Copilot-assisted, or fully agentic)
- Deciding priority and assignment

This feature introduces an **AI-powered triage agent** that automatically triggers when the `ai-triage` label is added to any GitHub issue. A GitHub Action orchestrates the process, calling the model via **GitHub Copilot CLI** (`copilot -p`) in programmatic mode to assess issue quality, enrich it with external context from Microsoft Learn, the Dynamics 365 Ideas Portal, and public forums, and then post a structured triage assessment as a comment with appropriate labels applied.

The agent operates in two internal phases:

1. **Phase 1 - Quality Assessment**: Evaluates whether the issue has enough information to act on
2. **Phase 2 - Enrichment & Triage**: Researches external context and produces the final triage recommendation

## 2. Goals

- **G1**: Reduce average issue triage time from ~15 minutes to under 2 minutes of PM review
- **G2**: Ensure consistent, structured triage assessments across all incoming issues
- **G3**: Surface relevant external context (documentation, community feedback, known ideas) that PMs would otherwise research manually
- **G4**: Provide actionable recommendations (complexity, value, risk, implementation path) so PMs can make quick accept/reject/defer decisions
- **G5**: Identify under-specified issues early and flag them before development starts
- **G6**: Fully automated - no manual CLI invocation required; just add a label

## 3. User Stories

- **US1**: As a product manager, I want to add the `ai-triage` label to issue #7 and receive a comprehensive triage assessment as a comment within 60 seconds, so I can quickly decide whether to accept, defer, or request more info.
- **US2**: As a product manager, I want the agent to flag poorly written issues with a `needs-info` label, so I know which issues need author follow-up before I invest triage time.
- **US3**: As a product manager, I want the agent to find related Microsoft Learn docs, Ideas Portal entries, and community discussions, so I have full context without manual research.
- **US4**: As a product manager, I want to see a complexity/value/risk assessment for each issue, so I can prioritize against other work items.
- **US5**: As a developer, I want the triage comment to include relevant code areas and documentation links, so I can start implementation faster when the issue is approved.
- **US6**: As a team lead, I want the agent to recommend whether an issue is best solved manually, with Copilot assistance, or fully agentically, so I can plan resources appropriately.

## 4. Functional Requirements

### 4.1 Trigger mechanism

- **FR1**: A GitHub Action workflow triggers on the `issues.labeled` event when the label `ai-triage` is added to any issue in `microsoft/BCAppsCampAIRHack`.
- **FR2**: The workflow must validate the issue is open before proceeding. If the issue is closed, skip processing and post no comment.
- **FR3**: The workflow installs GitHub Copilot CLI (`npm install -g @github/copilot`) and authenticates via `COPILOT_GITHUB_TOKEN` (a PAT with "Copilot Requests" permission).
- **FR4**: The workflow uses `issues: write` permission to post comments and manage labels.

### 4.2 Phase 1 - Issue quality assessment

- **FR5**: Read the full issue (title, body, comments, labels, author) using the GitHub REST API via `octokit`.
- **FR6**: Send the issue content to GPT-5.4 with a structured system prompt that evaluates quality across 5 dimensions, scoring each 0-20 for a total 0-100 score:

  | Dimension | What it measures | 0 (Poor) | 20 (Excellent) |
  |-----------|-----------------|----------|----------------|
  | **Clarity** | Is the problem clearly stated? | Vague, ambiguous | Crystal clear problem statement |
  | **Reproducibility** | Can someone act on this? | No steps, no context | Full repro steps or acceptance criteria |
  | **Context** | Environment, version, impact info | No context at all | Complete environment + impact assessment |
  | **Specificity** | Is the scope well-defined? | Overly broad/vague | Focused, well-scoped request |
  | **Actionability** | Can development start? | Missing critical info | Ready for immediate development |

- **FR7**: Based on the total quality score, assign a readiness verdict:

  - **READY** (75-100): Issue is well-specified; proceed to Phase 2 enrichment
  - **NEEDS WORK** (40-74): Issue has gaps; agent posts a comment requesting specific information but still proceeds to Phase 2 enrichment
  - **INSUFFICIENT** (0-39): Issue lacks critical information; agent posts a comment requesting specific information, applies `needs-info` label, and skips Phase 2

- **FR8**: For NEEDS WORK and INSUFFICIENT verdicts, the agent must specify exactly what information is missing (not generic "please add more details").

### 4.3 Phase 2 - Enrichment and triage

- **FR9**: Construct targeted search queries based on the issue content and BC app area (e.g., "Business Central Shopify connector API rate limit handling").
- **FR10**: Search Microsoft Learn BC documentation using web search queries scoped to `site:learn.microsoft.com/en-us/dynamics365/business-central/`.
- **FR11**: Search the Dynamics 365 Ideas Portal using web search queries scoped to `site:experience.dynamics.com`.
- **FR12**: Search public forums, Stack Overflow, and community discussions for related topics.
- **FR13**: Identify related code areas in the repository by mapping issue keywords to known app directories under `src/` (including `Apps/W1/`, `Business Foundation/`, `System Application/`, and `Tools/`).
- **FR14**: Compile all enrichment findings into a structured context section.
- **FR15**: Produce a triage assessment with the following data points:

  | Data Point | Description | Scale/Values |
  |-----------|-------------|-------------|
  | **Complexity** | Technical difficulty of implementation | Low / Medium / High / Very High |
  | **Value** | Business and user value | Low / Medium / High / Critical |
  | **Risk** | Risk of regressions or breaking changes | Low / Medium / High |
  | **Effort estimate** | T-shirt size estimate | XS / S / M / L / XL |
  | **Implementation path** | How this should be built | Manual / Copilot-Assisted / Agentic |
  | **Priority score** | Composite: (Value x Urgency) / (Effort x Risk) | 1-10 scale |
  | **Confidence** | How confident the agent is in its assessment | High / Medium / Low |
  | **Recommended action** | What the PM should do | Implement / Defer / Investigate / Reject |

- **FR16**: Provide a brief rationale for each data point (not just the score, but why).

### 4.4 Output - GitHub issue comment

- **FR17**: Post a single structured comment to the GitHub issue containing both phases' results.
- **FR18**: The comment must follow this template:

  ```markdown
  ## :robot: AI Triage Assessment

  > Automated assessment by the Issue Triage Agent (GPT-5.4)
  > Triggered by `ai-triage` label

  ---

  ### Issue Quality Score: XX/100 - VERDICT

  | Dimension | Score | Notes |
  |-----------|-------|-------|
  | Clarity | X/20 | ... |
  | Reproducibility | X/20 | ... |
  | Context | X/20 | ... |
  | Specificity | X/20 | ... |
  | Actionability | X/20 | ... |

  > [If NEEDS WORK/INSUFFICIENT]:
  > ### :warning: Information needed
  > - [ ] Specific item 1
  > - [ ] Specific item 2

  ---

  ### Triage Recommendation

  | Aspect | Assessment | Rationale |
  |--------|-----------|-----------|
  | Complexity | Medium | ... |
  | Value | High | ... |
  | Risk | Low | ... |
  | Effort | M | ... |
  | Impl. Path | Copilot-Assisted | ... |
  | Priority | 7/10 | ... |
  | Confidence | High | ... |

  **Recommended Action:** :white_check_mark: **Implement**

  **Summary:** 2-3 sentence executive summary for the PM.

  ---

  <details>
  <summary>:mag: Enrichment context (click to expand)</summary>

  #### Related documentation

  - [Title](url) - relevance note

  #### Ideas Portal & community

  - [Title](url) - relevance note

  #### Related code areas

  - `src/Apps/W1/[area]/` - relevance note

  </details>
  ```

### 4.5 GitHub labels

- **FR19**: Apply labels based on the assessment. The workflow should create labels if they don't exist (using the GitHub API):

  | Label | Color | When applied |
  |-------|-------|-------------|
  | `triage/ready` | `#0E8A16` (green) | Quality score >= 75 |
  | `triage/needs-info` | `#FBCA04` (yellow) | Quality score 40-74 |
  | `triage/insufficient` | `#E11D48` (red) | Quality score < 40 |
  | `priority/critical` | `#B60205` | Priority score >= 9 |
  | `priority/high` | `#D93F0B` | Priority score 7-8 |
  | `priority/medium` | `#F9D0C4` | Priority score 4-6 |
  | `priority/low` | `#C2E0C6` | Priority score 1-3 |
  | `complexity/low` | `#BFD4F2` | Complexity = Low |
  | `complexity/medium` | `#D4C5F9` | Complexity = Medium |
  | `complexity/high` | `#7057FF` | Complexity = High or Very High |
  | `effort/xs-s` | `#E6F5D0` | Effort = XS or S |
  | `effort/m` | `#FEF2C0` | Effort = M |
  | `effort/l-xl` | `#F9D0C4` | Effort = L or XL |
  | `path/manual` | `#BFDADC` | Impl. path = Manual |
  | `path/copilot-assisted` | `#C5DEF5` | Impl. path = Copilot-Assisted |
  | `path/agentic` | `#D4C5F9` | Impl. path = Agentic |
  | `Finance` | `#FBCA04` | Assigned to Finance team |
  | `SCM` | `#0E8A16` | Assigned to SCM team |
  | `Integration` | `#C5DEF5` | Assigned to Integration team |

- **FR20**: Before applying a label, remove any existing label from the same category (e.g., remove `priority/low` before applying `priority/high`).
- **FR21**: Do NOT remove the `ai-triage` trigger label (it serves as a record that triage was requested).

### 4.6 App area detection

- **FR22**: The agent should detect which Business Central app area the issue relates to by matching keywords in the issue title and body against known app directories across the full `src/` tree:

  | Keywords | App directory |
  |----------|--------------|
  | shopify, shop, e-commerce | `src/Apps/W1/Shopify/` |
  | data archive, archive, retention | `src/Apps/W1/DataArchive/` |
  | e-document, edocument, einvoice | `src/Apps/W1/EDocument/` |
  | subscription, billing, recurring | `src/Apps/W1/Subscription Billing/` |
  | quality, inspection | `src/Apps/W1/Quality Management/` |
  | no. series, number series | `src/Business Foundation/App/NoSeries/` |
  | system application | `src/System Application/App/` |
  | copilot, ai, journal | `src/Apps/W1/` (general) |
  | *(25+ additional area mappings)* | *(see config.js for full list)* |

  A dynamic fallback scans directory names under `src/` (2 levels deep) when no keyword match is found.

- **FR23**: The detected app area should be used to scope the codebase search and improve enrichment query relevance.

## 5. Non-goals (out of scope)

- **NG1**: Auto-assignment of issues to specific developers (PM decides; team assignment via Finance/SCM/Integration labels is automated)
- **NG2**: Auto-closing or auto-rejecting issues (PM decides)
- **NG3**: Azure DevOps integration (ADO toggle is OFF in this repo)
- **NG4**: Batch processing of multiple issues in one action run
- **NG5**: Viva Engage integration (requires authenticated corporate access)
- **NG6**: Automatic re-triage when issue content is updated (future: could re-trigger on `issues.edited`)
- **NG7**: Token usage or cost tracking
- **NG8**: Custom per-repository configuration (hardcoded to this repo for PoC)

## 6. Design considerations

### 6.1 Architecture overview

```
                                     GitHub Repository
                                     microsoft/BCAppsCampAIRHack
                                     
  User adds                          .github/workflows/
  "ai-triage" ──────────────────────> issue-triage.yml
  label to                                 │
  Issue #7                                 │ triggers on:
                                           │ issues.labeled
                                           v
                                     ┌─────────────┐
                                     │ GitHub Action│
                                     │  Runner      │
                                     └──────┬──────┘
                                            │
                              ┌─────────────┴──────────────┐
                              │                            │
                              v                            v
                    ┌─────────────────┐        ┌───────────────────┐
                    │ Phase 1:        │        │ GitHub REST API   │
                    │ Quality Assess  │        │ (read issue,      │
                    │ (Copilot CLI)   │        │  post comment,    │
                    └────────┬────────┘        │  manage labels)   │
                             │                 └───────────────────┘
                    Score >= 75?
                    ┌────────┴────────┐
                    │ Yes             │ No
                    v                 v
          ┌─────────────────┐   Post "needs info"
          │ Phase 2:        │   comment + label
          │ Enrichment      │
          │ (Copilot CLI    │
          │  + code search) │
          └────────┬────────┘
                   │
                   v
          ┌─────────────────┐
          │ Post triage     │
          │ comment +       │
          │ apply labels    │
          │ (incl. team:    │
          │  Finance/SCM/   │
          │  Integration)   │
          └─────────────────┘
```

### 6.2 File structure

```
.github/
  workflows/
    issue-triage.yml            # GitHub Action workflow definition
  scripts/
    triage/
      index.js                  # Main orchestration script
      config.js                 # Labels, thresholds, app areas, team keywords, mapping functions
      models-client.js          # Copilot CLI wrapper (stdin-based, with retry)
      github-client.js          # GitHub REST/GraphQL client (comments, labels, issue types, re-triage)
      phase1-assess.js          # Phase 1: quality assessment (reads skill files)
      phase2-enrich.js          # Phase 2: enrichment & triage (reads skill files, parallel fetches)
      code-reader.js            # Repository AL code reader (15KB cap)
      ado-client.js             # Azure DevOps work item search (with relevance scoring)
      ideas-client.js           # Dynamics 365 Ideas Portal search (fuzzy matching)
      marketplace-client.js     # AppSource marketplace context
      duplicate-detector.js     # Jaccard similarity duplicate detection
      format-comment.js         # Issue comment formatter (compact + verbose fallback)
      format-report.js          # Wiki report formatter (TL;DR + collapsible details)
      wiki-client.js            # Wiki publisher (configurable target repo)
      package.json              # Dependencies and test script
      tests/                    # Unit tests (50 tests)
plugins/
  triage/
    .claude-plugin/plugin.json  # Plugin metadata
    skills/triage/
      SKILL.md                  # BC/AL glossary + process overview (single source of truth)
      triage-assess.md          # Phase 1 quality rubric (single source of truth)
      triage-enrich.md          # Phase 2 triage criteria (single source of truth)
      triage-reference.md       # App areas, team keywords, labels (documents config.js)
```

> **Note**: The `prompts/` directory has been removed. Phase 1 and Phase 2 system prompts are now built at runtime from the skill files in `plugins/triage/skills/triage/`, which serve as the single source of truth for all triage domain knowledge.

### 6.3 GitHub Action workflow design

See `.github/workflows/issue-triage.yml` for the current workflow. Key configuration:

- **Trigger**: `issues.labeled` when `ai-triage` label is added and issue is open
- **Permissions**: `contents: write` (for wiki push), `issues: write`
- **Concurrency**: One triage per issue at a time (`cancel-in-progress: true`)
- **Environment variables**: `GITHUB_TOKEN`, `COPILOT_GITHUB_TOKEN`, `ISSUE_NUMBER`, `REPO_OWNER`, `REPO_NAME`, `ADO_PAT`, `TRIAGE_REPO`

### 6.4 Copilot CLI call pattern

Each phase makes a single call to the model via GitHub Copilot CLI. The combined prompt is passed via stdin using `execFileSync`:

```javascript
execFileSync('copilot',
  ['-s', '--no-ask-user', '--no-custom-instructions', `--model=${MODEL_NAME}`],
  { input: combinedPrompt, timeout: 420_000 }
);
```

The `-s` (silent) flag ensures clean output. `--no-ask-user` prevents interactive prompts. `--no-custom-instructions` prevents repo instruction files from being loaded. Authentication is via `COPILOT_GITHUB_TOKEN` (a PAT with "Copilot Requests" permission). Timeout is 7 minutes to accommodate large prompts.

### 6.5 Phase 1 system prompt design

The Phase 1 system prompt instructs GPT-5.4 to:

1. Read the issue title, body, and any comments
2. Score each of the 5 dimensions (0-20)
3. Determine the readiness verdict (READY / NEEDS WORK / INSUFFICIENT)
4. List specific missing information items (if any)
5. Return a JSON response:

```json
{
  "quality_score": {
    "clarity": { "score": 15, "notes": "..." },
    "reproducibility": { "score": 18, "notes": "..." },
    "context": { "score": 12, "notes": "..." },
    "specificity": { "score": 16, "notes": "..." },
    "actionability": { "score": 14, "notes": "..." },
    "total": 75
  },
  "verdict": "READY",
  "missing_info": [],
  "detected_app_area": "Shopify",
  "issue_type": "bug",
  "summary": "Brief one-line summary of what the issue is about"
}
```

### 6.6 Phase 2 system prompt design

The Phase 2 system prompt receives the Phase 1 output plus search results and instructs GPT-5.4 to:

1. Analyze the enrichment context from web searches
2. Score complexity, value, risk, and effort
3. Determine the optimal implementation path
4. Calculate the priority score
5. Provide a recommended action with rationale
6. Return a JSON response:

```json
{
  "enrichment": {
    "documentation": [
      { "title": "...", "url": "...", "relevance": "..." }
    ],
    "ideas_portal": [
      { "title": "...", "url": "...", "relevance": "..." }
    ],
    "community": [
      { "title": "...", "url": "...", "relevance": "..." }
    ],
    "code_areas": [
      { "path": "src/Apps/W1/Shopify/...", "relevance": "..." }
    ]
  },
  "triage": {
    "complexity": { "rating": "Medium", "rationale": "..." },
    "value": { "rating": "High", "rationale": "..." },
    "risk": { "rating": "Low", "rationale": "..." },
    "effort": { "rating": "M", "rationale": "..." },
    "implementation_path": { "rating": "Copilot-Assisted", "rationale": "..." },
    "priority_score": { "score": 7, "rationale": "..." },
    "confidence": { "rating": "High", "rationale": "..." },
    "recommended_action": { "action": "Implement", "rationale": "..." }
  },
  "executive_summary": "2-3 sentence summary for the PM"
}
```

### 6.7 Enrichment strategy

Enrichment data is fetched in parallel before the Phase 2 model call:

1. **Repository code** (`code-reader.js`): Reads AL files from the detected app area directory, scored by keyword relevance, capped at 15KB
2. **Ideas Portal** (`ideas-client.js`): Fetches from `experience.dynamics.com/_odata/ideas`, filtered to BC forum, matched with fuzzy keyword matching and BC domain synonyms
3. **Azure DevOps** (`ado-client.js`): WIQL queries against Dynamics SMB project, searches both titles and descriptions, results scored by keyword matches with bracketed tags stripped
4. **AppSource Marketplace** (`marketplace-client.js`): Provides search terms and URL for the model to estimate ecosystem interest (no public API available)
5. **Duplicate detection** (`duplicate-detector.js`): Compares against recent open issues using Jaccard similarity on keyword sets

Key term extraction (`phase2-enrich.js`) prioritizes known BC domain phrases (50+), then bigrams (top 5), then single high-frequency words (top 8), yielding up to 12 search terms.

### 6.8 Idempotency and re-triage

If the `ai-triage` label is removed and re-added (re-triage):

- The agent detects existing `## :robot: AI Triage Assessment` comments
- Extracts previous scores (quality, priority, per-dimension) from the last triage comment
- Notes this is a re-triage in the new comment header
- Wiki report shows a comparison table with score deltas
- Wiki page is overwritten (previous versions in wiki git history)
- Labels and issue type are updated to reflect the new assessment

## 7. Technical considerations

### 7.1 Dependencies

| Dependency | Purpose | Version |
|-----------|---------|---------|
| `@octokit/rest` | GitHub REST API client | Latest |
| `@github/copilot` | GitHub Copilot CLI for model inference | Latest |

Minimal dependency footprint for fast CI install. Native `fetch` (Node 20) is used for ADO and Ideas Portal API calls.

### 7.2 Error handling

| Scenario | Behavior |
|----------|----------|
| Issue is closed | Skip processing, log info |
| Near-empty issue (title < 10 chars, body < 20 chars) | Short-circuit as INSUFFICIENT without model call |
| Copilot CLI timeout (7 min) | Retry once, then fail with error comment |
| Copilot CLI returns malformed JSON | Retry once with 2s delay, then fail |
| GitHub API 5xx | Retry up to 3 times with increasing delay (3s, 6s) |
| ADO/Ideas Portal fetch fails | Continue with Phase 2 using available data (graceful degradation) |
| Wiki publish fails | Fall back to verbose inline comment (no data lost) |
| Model response has wrong types | Coerce fixable values (e.g., string→number), derive verdict from score if invalid |
| Label already processed | Check for existing triage comment, note re-triage, show score diff |

### 7.3 Security

- `GITHUB_TOKEN` for GitHub API and wiki push (auto-provided or PAT for cross-repo wiki)
- `COPILOT_GITHUB_TOKEN` for Copilot CLI model inference
- `ADO_PAT` (optional) for Azure DevOps work item search
- The agent NEVER modifies issue title, body, or assignees (read issue, write comments/labels/type only)
- Triage knowledge stored in skill files in the repo, fully auditable
- Wiki reports can be directed to a private repo via `TRIAGE_REPO` for access control

### 7.4 Performance target

- Total execution time: under 60 seconds
- Phase 1 GPT call: ~5-10 seconds
- Web searches (3 parallel): ~5-10 seconds
- Phase 2 GPT call: ~10-15 seconds
- GitHub API calls (read issue, post comment, manage labels): ~5 seconds
- Overhead (checkout, npm install, boot): ~15-20 seconds

### 7.5 Repository context

For the PoC, the repository owner/name comes from the GitHub Action event context (`github.repository_owner`, `github.event.repository.name`). The app area detection uses a hardcoded mapping of keywords to `src/Apps/W1/` subdirectories specific to this repo.

## 8. Success metrics

- **SM1**: 90%+ of READY-scored issues are accepted by PM without requesting additional info
- **SM2**: 90%+ of NEEDS WORK/INSUFFICIENT issues are correctly identified
- **SM3**: Enrichment context is rated "useful" by PM for 80%+ of issues
- **SM4**: Triage assessment matches PM's independent judgment 75%+ of the time
- **SM5**: End-to-end execution completes in under 60 seconds per issue
- **SM6**: Zero false positives on label application (no conflicting labels)

## 9. Open questions (status)

- **OQ1**: ~~Should the agent also detect duplicate issues?~~ **Resolved** — Implemented via Jaccard similarity against recent open issues (≥ 35% overlap flagged).
- **OQ2**: Should there be a "Suggested Assignee" field based on git blame of related code areas? (Deferred)
- **OQ3**: How should the agent handle issues that reference internal Microsoft systems or private information? (Limitation: not handled)
- **OQ4**: ~~Should re-triage remove old triage labels?~~ **Resolved** — Yes, old labels in each category are removed before applying new ones.
- **OQ5**: Should there be a separate `ai-triage-complete` label? (Not implemented — the triage status labels serve this purpose)

---

**Last Updated**: 2026-03-24
