# Issue Triage Agent - Implementation Tasks

> **Feature**: GitHub Issue Enrichment & Triage Agent
> **Design**: `docs/features/issue-triage-agent/design.md`
> **Generated**: 2026-03-11 by jeschulz

---

## Tasks

### Phase 1: Project setup and infrastructure

**Status**: Not Started
**Progress**: 0/7 tasks complete (0%)
**Phase Started**: TBD
**Phase Completed**: TBD

- [ ] 1.0 Create project foundation, directory structure, package.json, and configuration
  - **Relevant Documentation:**
    - `docs/features/issue-triage-agent/design.md` - Feature requirements, file structure (section 6.2), label definitions (FR19), app area mappings (FR22)
  - [ ] 1.1 Create directory structure for the triage agent
    - Create `.github/scripts/triage/` directory
    - Create `.github/scripts/triage/prompts/` subdirectory
    - Create `.github/workflows/` directory (if it doesn't exist)
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 1.2 Create `package.json` with dependencies
    - Create `.github/scripts/triage/package.json`
    - Add dependency: `@octokit/rest` (GitHub REST API client)
    - Set `"type": "module"` for ES module support
    - Set Node engine to `>=20` (native fetch available, no `node-fetch` needed)
    - Add `"name": "issue-triage-agent"`, `"version": "1.0.0"`, `"private": true`
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 1.3 Create `config.js` with all static configuration
    - Create `.github/scripts/triage/config.js`
    - Define label categories and colors from design FR19 (18 labels across 7 categories: triage status, priority, complexity, effort, implementation path)
    - Define quality score thresholds: READY (75-100), NEEDS WORK (40-74), INSUFFICIENT (0-39) per FR7
    - Define app area keyword mappings per FR22 (Shopify, Data Archive, E-Document, Subscription Billing, Quality Management, etc.)
    - Define GitHub Models API endpoint: `https://models.github.ai/inference/chat/completions`
    - Define model name: `openai/gpt-5.4`
    - Export all constants as named exports
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - **Parallel Group A** (after 1.3 completes - both clients are independent of each other):
    - [ ] 1.4 Create `models-client.js` - GitHub Models API wrapper
      - Create `.github/scripts/triage/models-client.js`
      - Implement `callGPT(systemPrompt, userMessage)` function
      - Use native `fetch` to POST to `https://models.github.ai/inference/chat/completions`
      - Set headers: `Authorization: Bearer ${GITHUB_TOKEN}`, `Content-Type: application/json`
      - Request body: `model: "openai/gpt-5.4"`, `temperature: 0.3`, `response_format: { type: "json_object" }`
      - Parse and return the JSON content from `choices[0].message.content`
      - Implement retry logic: on 429 (rate limit) or 5xx, wait 5 seconds and retry once
      - On persistent failure, throw descriptive error
      - Read `GITHUB_TOKEN` from `process.env`
      - **Started**: TBD
      - **Completed**: TBD
      - **Duration**: TBD
    - [ ] 1.5 Create `github-client.js` - GitHub API helper
      - Create `.github/scripts/triage/github-client.js`
      - Import `Octokit` from `@octokit/rest`
      - Initialize Octokit with `process.env.GITHUB_TOKEN`
      - Implement `getIssue(owner, repo, issueNumber)` - returns issue title, body, comments, labels, author, state
      - Implement `postComment(owner, repo, issueNumber, body)` - posts markdown comment to issue
      - Implement `ensureLabel(owner, repo, name, color, description)` - creates label if it doesn't exist (catch 422 "already_exists")
      - Implement `addLabels(owner, repo, issueNumber, labels)` - adds labels to issue
      - Implement `removeLabel(owner, repo, issueNumber, label)` - removes label, catches 404 if not present
      - Implement `manageCategoryLabels(owner, repo, issueNumber, category, newLabel)` - removes all labels in category prefix (e.g., `priority/`) then adds the new one per FR20
      - Implement `checkExistingTriage(owner, repo, issueNumber)` - searches comments for `## :robot: AI Triage Assessment` header, returns boolean for idempotency (section 6.8)
      - **Started**: TBD
      - **Completed**: TBD
      - **Duration**: TBD
  - [ ] 1.6 Run `npm install` and verify dependencies resolve
    - Run `cd .github/scripts/triage && npm install`
    - Verify `node_modules/` is created with `@octokit/rest`
    - Add `.github/scripts/triage/node_modules/` to `.gitignore` if not already excluded
    - Verify `package-lock.json` is generated
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 1.7 Create phase completion summary
    - Create `docs/tasks/TASK-1.0-PROJECT-SETUP-COMPLETION-SUMMARY.md`
    - Include: directory structure created, dependencies installed, config defined, API clients tested
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD

---

### Phase 2: AI system prompts and phase logic

**Status**: Not Started
**Progress**: 0/7 tasks complete (0%)
**Phase Started**: TBD
**Phase Completed**: TBD

- [ ] 2.0 Write system prompts and implement Phase 1 (quality assessment) and Phase 2 (enrichment & triage) modules
  - **Relevant Documentation:**
    - `docs/features/issue-triage-agent/design.md` - Phase 1 scoring rubric (FR5-FR8), Phase 2 assessment criteria (FR9-FR16), JSON response schemas (sections 6.5, 6.6), comment template (FR18), web search strategy (section 6.7)
  - **Parallel Group A** (prompts are independent of each other):
    - [ ] 2.1 Write Phase 1 system prompt (`system-phase1.md`)
      - Create `.github/scripts/triage/prompts/system-phase1.md`
      - Instruct GPT-5.4 to act as a senior QA analyst evaluating GitHub issue quality
      - Define the 5 scoring dimensions (Clarity, Reproducibility, Context, Specificity, Actionability) with detailed rubrics for each score level (0, 5, 10, 15, 20) per FR6
      - Include examples of well-scored and poorly-scored issues for calibration
      - Define the readiness verdict logic: READY >= 75, NEEDS WORK 40-74, INSUFFICIENT < 40
      - For NEEDS WORK and INSUFFICIENT: instruct to list specific missing items, NOT generic requests per FR8
      - Require app area detection from keywords (Shopify, Data Archive, etc.)
      - Require issue type classification (bug, feature request, enhancement, question)
      - Specify the exact JSON output schema from design section 6.5:
        ```json
        {
          "quality_score": { "clarity": { "score": N, "notes": "..." }, ... , "total": N },
          "verdict": "READY|NEEDS WORK|INSUFFICIENT",
          "missing_info": ["specific item 1", ...],
          "detected_app_area": "...",
          "issue_type": "bug|feature|enhancement|question",
          "summary": "one-line summary"
        }
        ```
      - **Started**: TBD
      - **Completed**: TBD
      - **Duration**: TBD
    - [ ] 2.2 Write Phase 2 system prompt (`system-phase2.md`)
      - Create `.github/scripts/triage/prompts/system-phase2.md`
      - Instruct GPT-5.4 to act as a senior product manager/technical lead performing issue triage
      - Define scoring criteria for each triage dimension (Complexity, Value, Risk, Effort, Implementation Path, Priority, Confidence) with detailed rubrics per FR15
      - Define the implementation path decision matrix:
        - **Manual**: Simple config change, documentation update, or well-understood pattern
        - **Copilot-Assisted**: Code changes following existing patterns where AI can help with boilerplate
        - **Agentic**: Complex multi-file change where AI can drive the full implementation
      - Define priority score formula: `(Value_weight x Urgency_weight) / (Effort_weight x Risk_weight)` normalized to 1-10
      - Define recommended action logic: Implement (priority >= 6 AND confidence High/Medium), Defer (priority 3-5 OR effort L-XL), Investigate (confidence Low), Reject (value Low AND effort >= M)
      - Instruct to synthesize enrichment search results into structured context
      - Specify the exact JSON output schema from design section 6.6
      - Include instruction to write an executive summary accessible to non-technical PMs
      - **Started**: TBD
      - **Completed**: TBD
      - **Duration**: TBD
  - **Parallel Group B** (after Group A completes - each phase module depends on its prompt but not the other module):
    - [ ] 2.3 Implement `phase1-assess.js`
      - Create `.github/scripts/triage/phase1-assess.js`
      - Import `callGPT` from `models-client.js` and `fs` for reading the prompt file
      - Implement `assessIssueQuality(issue)` function:
        1. Read `system-phase1.md` prompt from `prompts/` directory (use `import.meta.url` for path resolution)
        2. Format user message with issue title, body, comments (concatenated), labels, and author
        3. Call `callGPT(systemPrompt, userMessage)`
        4. Parse and validate the JSON response (check all required fields exist)
        5. Return the parsed assessment object
      - Export `assessIssueQuality` as default export
      - **Started**: TBD
      - **Completed**: TBD
      - **Duration**: TBD
    - [ ] 2.4 Implement `phase2-enrich.js`
      - Create `.github/scripts/triage/phase2-enrich.js`
      - Import `callGPT` from `models-client.js` and `fs` for reading the prompt file
      - Implement `searchWeb(query)` helper function:
        1. Use native `fetch` to call a web search API or construct search URLs
        2. For the PoC, use the GitHub Models API itself to synthesize search results by including search instructions in the Phase 2 prompt (the model has web knowledge up to its training cutoff)
        3. Construct 3 targeted queries per design section 6.7:
           - `site:learn.microsoft.com dynamics365 business-central [keywords]`
           - `site:experience.dynamics.com [keywords]`
           - `business central [keywords] site:stackoverflow.com OR site:github.com`
      - Implement `enrichAndTriage(issue, phase1Result)` function:
        1. Read `system-phase2.md` prompt from `prompts/` directory
        2. Format user message with: issue content, Phase 1 assessment results, detected app area, and search query keywords
        3. Call `callGPT(systemPrompt, userMessage)`
        4. Parse and validate the JSON response
        5. Return the parsed triage object
      - Export `enrichAndTriage` as default export
      - **Started**: TBD
      - **Completed**: TBD
      - **Duration**: TBD
  - [ ] 2.5 Create unit test smoke check
    - Create `.github/scripts/triage/test-prompts.js`
    - Write a simple validation script that:
      1. Reads both prompt files and verifies they exist and are non-empty
      2. Validates config.js exports all expected constants
      3. Validates JSON schemas match design spec (mock responses)
    - Run with `node test-prompts.js` - should exit 0 on success
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 2.6 Update project documentation
    - Create `.github/scripts/triage/CLAUDE.md` with overview and pointers to all files
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 2.7 Create phase completion summary
    - Create `docs/tasks/TASK-2.0-AI-PROMPTS-PHASE-LOGIC-COMPLETION-SUMMARY.md`
    - Include: prompt design decisions, scoring rubric rationale, JSON schemas, test results
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD

---

### Phase 3: Orchestration, comment formatting, and GitHub Action workflow

**Status**: Not Started
**Progress**: 0/6 tasks complete (0%)
**Phase Started**: TBD
**Phase Completed**: TBD

- [ ] 3.0 Create the main orchestrator, comment formatter, and GitHub Action workflow
  - **Relevant Documentation:**
    - `docs/features/issue-triage-agent/design.md` - Architecture overview (section 6.1), workflow YAML (section 6.3), comment template (FR18), label management (FR19-FR21), idempotency (section 6.8), error handling (section 7.2)
  - [ ] 3.1 Create `format-comment.js` - Comment formatting module
    - Create `.github/scripts/triage/format-comment.js`
    - Implement `formatTriageComment(phase1Result, phase2Result, isRetriage)` function
    - Build the markdown comment following the exact template in design FR18:
      - Header: `## :robot: AI Triage Assessment` with GPT-5.4 attribution
      - Quality score table with all 5 dimensions and per-dimension notes
      - If NEEDS WORK/INSUFFICIENT: "Information needed" section with checklist items from `phase1Result.missing_info`
      - Triage recommendation table with all 8 data points and rationales
      - Recommended action with emoji (`:white_check_mark:` Implement, `:hourglass:` Defer, `:mag:` Investigate, `:x:` Reject)
      - Executive summary
      - Collapsible enrichment context section (`<details>`) with documentation links, Ideas Portal links, community links, and related code areas
    - If `isRetriage` is true, add a note: "> :arrows_counterclockwise: This is a re-triage. See earlier assessment comments for history."
    - Implement `formatInsufficientComment(phase1Result)` for INSUFFICIENT issues (Phase 2 skipped):
      - Quality score table
      - Information needed section (prominent, not collapsible)
      - Clear message asking the issue author to provide the missing information
    - Export both functions
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 3.2 Create `index.js` - Main orchestrator
    - Create `.github/scripts/triage/index.js`
    - Read environment variables: `GITHUB_TOKEN`, `ISSUE_NUMBER`, `REPO_OWNER`, `REPO_NAME`
    - Validate all env vars are present; exit with error code 1 and descriptive message if any are missing
    - Implement main flow:
      1. Initialize GitHub client
      2. Fetch issue details via `getIssue()` - if issue not found or closed, log and exit cleanly
      3. Check for existing triage via `checkExistingTriage()` - set `isRetriage` flag
      4. Run Phase 1: call `assessIssueQuality(issue)`
      5. Log Phase 1 results to stdout (quality score, verdict)
      6. If verdict is INSUFFICIENT (score < 40):
         - Format comment via `formatInsufficientComment(phase1Result)`
         - Post comment
         - Apply `triage/insufficient` label (remove other triage/* labels first)
         - Apply `needs-info` label (this is an additional signal label)
         - Exit
      7. If verdict is NEEDS WORK or READY (score >= 40):
         - Run Phase 2: call `enrichAndTriage(issue, phase1Result)`
         - Format full comment via `formatTriageComment(phase1Result, phase2Result, isRetriage)`
         - Post comment
         - Apply labels per category: triage status, priority, complexity, effort, implementation path
         - Use `manageCategoryLabels()` to handle conflicts per FR20
      8. Log completion summary to stdout
    - Wrap entire main flow in try/catch:
      - On error: post a comment noting the triage failed with error summary, then exit code 1
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 3.3 Create `issue-triage.yml` GitHub Action workflow
    - Create `.github/workflows/issue-triage.yml`
    - Workflow name: `Issue Triage Agent`
    - Trigger: `on: issues: types: [labeled]`
    - Permissions: `contents: read`, `issues: write`, `models: read`
    - Job condition: `if: github.event.label.name == 'ai-triage' && github.event.issue.state == 'open'`
    - Steps:
      1. `actions/checkout@v4` (to access prompt files and config)
      2. `actions/setup-node@v4` with `node-version: '20'`
      3. `npm ci` in `working-directory: .github/scripts/triage`
      4. `node index.js` in `working-directory: .github/scripts/triage` with env vars:
         - `GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}`
         - `ISSUE_NUMBER: ${{ github.event.issue.number }}`
         - `REPO_OWNER: ${{ github.repository_owner }}`
         - `REPO_NAME: ${{ github.event.repository.name }}`
    - Add concurrency group: `triage-${{ github.event.issue.number }}` with `cancel-in-progress: true` (prevents duplicate runs if label is added/removed/re-added quickly)
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 3.4 Update `.gitignore` for triage agent
    - Add `.github/scripts/triage/node_modules/` to `.gitignore`
    - Verify `package-lock.json` is NOT in `.gitignore` (it should be committed)
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 3.5 Update project documentation
    - Update `.github/scripts/triage/CLAUDE.md` with orchestration flow and workflow details
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 3.6 Create phase completion summary
    - Create `docs/tasks/TASK-3.0-ORCHESTRATION-WORKFLOW-COMPLETION-SUMMARY.md`
    - Include: orchestration flow, error handling strategy, workflow configuration, concurrency handling
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD

---

### Phase 4: End-to-end testing and validation

**Status**: Not Started
**Progress**: 0/7 tasks complete (0%)
**Phase Started**: TBD
**Phase Completed**: TBD

- [ ] 4.0 Test the agent against live GitHub issues and iterate on quality
  - **Relevant Documentation:**
    - `docs/features/issue-triage-agent/design.md` - Success metrics (section 8), error handling (section 7.2), performance targets (section 7.4)
  - [ ] 4.1 Commit and push to trigger the GitHub Action
    - Stage all new files: workflow, scripts, prompts, config, package.json, package-lock.json
    - Commit with descriptive message: "Add GitHub Issue Triage Agent (PoC)"
    - Push to a feature branch (e.g., `feature/issue-triage-agent`)
    - Verify the workflow file is picked up by GitHub Actions (check Actions tab)
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 4.2 Test with issue #7 (sparse issue - expected: INSUFFICIENT or NEEDS WORK)
    - Issue #7: "Data Archive cleanup job not respecting retention policy date filter" - body: "bug in data archive"
    - Add the `ai-triage` label to issue #7
    - Wait for the GitHub Action to complete (target: < 60 seconds)
    - Verify the action ran successfully in the Actions tab
    - Verify a triage comment was posted with quality score and correct verdict
    - Expected: low quality score (< 40) due to minimal body text
    - Expected: `triage/insufficient` or `triage/needs-info` label applied
    - Expected: specific missing info items listed (not generic)
    - Verify: detected app area should be "Data Archive"
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 4.3 Test with issue #5 (detailed issue - expected: READY)
    - Issue #5: "Shopify Connector: Sync fails silently when product metafields exceed API rate limit" - has full description, repro steps, expected/actual behavior, environment info
    - Add the `ai-triage` label to issue #5
    - Wait for the GitHub Action to complete
    - Verify a full triage comment was posted with:
      - Quality score >= 75 (READY verdict)
      - Full triage recommendation table (all 8 data points)
      - Enrichment context with Microsoft Learn links, community references
      - Related code area: `src/Apps/W1/Shopify/`
    - Verify appropriate labels applied (triage/ready + priority + complexity + effort + path)
    - Verify: detected app area should be "Shopify"
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 4.4 Test with issue #6 (feature request - expected: READY or NEEDS WORK)
    - Issue #6: "Add support for Copilot-assisted journal entry creation" - has description and example but no formal acceptance criteria
    - Add the `ai-triage` label to issue #6
    - Wait for the GitHub Action to complete
    - Verify triage comment quality and scoring accuracy
    - Expected: implementation path should recommend "Copilot-Assisted" or "Agentic"
    - Verify enrichment context includes relevant Copilot/AI documentation from Microsoft Learn
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 4.5 Validate label management
    - Verify no conflicting labels exist (e.g., both `priority/high` and `priority/low` on same issue)
    - If re-triaging an issue (remove `ai-triage` label then re-add), verify:
      - Old triage labels are replaced with new ones
      - New comment is posted (not editing old one)
      - Re-triage note appears in the new comment
    - Verify `ai-triage` label is not removed by the agent per FR21
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 4.6 Iterate on prompt quality based on test results
    - Review all 3 triage comments for accuracy and usefulness
    - Adjust Phase 1 scoring rubric if scores seem too harsh or too lenient
    - Adjust Phase 2 enrichment instructions if context is too generic or irrelevant
    - Adjust comment formatting if readability can be improved
    - Re-run triage on any issue where quality was unsatisfactory
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD
  - [ ] 4.7 Create phase completion summary
    - Create `docs/tasks/TASK-4.0-TESTING-VALIDATION-COMPLETION-SUMMARY.md`
    - Include: test results for all 3 issues, scoring accuracy, label correctness, prompt iterations made, performance metrics
    - **Started**: TBD
    - **Completed**: TBD
    - **Duration**: TBD

---

## Dependency map

```
Phase 1 (Setup)
  1.1 → 1.2 → 1.3 → [1.4 || 1.5] → 1.6 → 1.7
                                         │
Phase 2 (Prompts & Logic)                v
  [2.1 || 2.2] → [2.3 || 2.4] → 2.5 → 2.6 → 2.7
                                              │
Phase 3 (Orchestration)                       v
  3.1 → 3.2 → 3.3 → 3.4 → 3.5 → 3.6
                                    │
Phase 4 (Testing)                   v
  4.1 → 4.2 → 4.3 → 4.4 → 4.5 → 4.6 → 4.7
```

**Legend**: `→` = sequential dependency, `||` = parallel (within Parallel Group)

---

## Parallelization summary

| Phase | Parallel Group | Tasks | Prerequisite |
|-------|---------------|-------|-------------|
| 1 | Group A | 1.4 (models-client.js), 1.5 (github-client.js) | 1.3 (config.js) |
| 2 | Group A | 2.1 (Phase 1 prompt), 2.2 (Phase 2 prompt) | Phase 1 complete |
| 2 | Group B | 2.3 (phase1-assess.js), 2.4 (phase2-enrich.js) | Group A (prompts) |

Phases 3 and 4 are fully sequential because:

- Phase 3: The orchestrator (3.2) depends on the comment formatter (3.1), and the workflow (3.3) needs the orchestrator to exist
- Phase 4: Each test builds on the previous (commit first, test sparse issue, test detailed issue, test feature request, validate labels, then iterate)

---

**Last Updated**: 2026-03-11 by jeschulz
