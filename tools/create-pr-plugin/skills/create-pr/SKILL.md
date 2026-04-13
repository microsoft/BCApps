---
name: create-pr
description: >
  Create a pull request with intelligent SME reviewer assignment, AI decision
  context, and structured "How to Review" guidance. Analyzes the diff to identify
  app-level and domain-level reviewers, extracts decisions from the Claude
  conversation, and creates the PR on GitHub or Azure DevOps. Posts inline review
  comments tagging each SME on their most relevant file.
  Use when the user says "create pr", "open pr", "submit pr", or "/create-pr".
user-invocable: true
argument-hint: "[work-item-id or github-issue-number]"
allowed-tools: Bash(gh *), Bash(git *), Bash(ls *), Bash(rm *), Read, Write, Glob, Grep, mcp__ado__repo_create_pull_request, mcp__ado__repo_create_pull_request_thread, mcp__ado__repo_update_pull_request_reviewers, mcp__ado__repo_get_repo_by_name_or_id
---

# Create PR Skill

Create a pull request with structured description, AI decision context, SME reviewer assignment, and inline review comments.

## Prerequisites

Before starting, verify:

1. **Git authentication**: Run `gh auth status`. If it fails, stop and ask the user to authenticate.
2. **Clean state**: Run `git status --porcelain`. Warn if there are uncommitted changes — they won't be in the PR.
3. **Branch**: Run `git rev-parse --abbrev-ref HEAD`. Verify it's NOT `main` or `master`. If it is, stop — the user needs to be on a feature branch.
4. **Commits exist**: Run `git log main..HEAD --oneline`. If empty, stop — there's nothing to create a PR for.

## Step 0: Platform Detection

Determine whether this is a GitHub or ADO repo:

```
git remote get-url origin
```

- If the URL contains `github.com` → **GitHub mode** (use `gh pr create`)
- If the URL contains `visualstudio.com` or `dev.azure.com` → **ADO mode** (use MCP tools)
- If ambiguous, ask the user which platform to target

For **ADO mode**, extract from the URL:
- **Project name**: the URL segment after the org (e.g., `Dynamics%20SMB` → `Dynamics SMB`)
- **Repository name**: the last segment (e.g., `NAV`)

## Step 1: Analyze the Diff

Run these commands and save the results:

```bash
# Changed file list (for app/module matching)
git diff main...HEAD --name-only

# Full diff (for domain keyword scanning — only + lines matter)
git diff main...HEAD

# Commit history (for summary generation)
git log main..HEAD --oneline

# Diff stats (for identifying largest changed files)
git diff main...HEAD --stat
```

If `main` doesn't exist, try `master` as the base branch.

## Step 2: Load Reviewers Config

Read `reviewers.md` from the same directory as this SKILL.md file. Parse all the markdown tables under **App / Module Reviewers** (there are multiple tables grouped by section) and the **Domain Reviewers** table. Each table has columns: Area, GitHub, ADO.

Collect all rows across all App / Module Reviewers tables into a single lookup map: `area name → { github: [...], ado: [...] }`.

If `reviewers.md` is missing or unreadable:
- Warn: "No reviewers.md found. Will use CODEOWNERS defaults only. No inline review comments will be posted."
- Continue without reviewer assignment.

## Step 3: App / Module Detection

For each changed file, extract the **area name** using these rules (first match wins):

### BCApps repo paths (when CWD is inside `App/BCApps/`)

| File path pattern | Area name |
|-------------------|-----------|
| `src/Apps/W1/<AppName>/...` | `<AppName>` (e.g., `Shopify`) |
| `src/System Application/App/<Module>/...` | `System Application / <Module>` |
| `src/System Application/...` (no module match) | `System Application (other)` |
| `src/Business Foundation/App/<Module>/...` | `Business Foundation / <Module>` |
| `src/Business Foundation/...` (no module match) | `Business Foundation (other)` |
| `build/**`, `.github/**`, `.AL-Go/**`, `*.ps1` | `Engineering Systems` |

### NAV repo paths (when CWD is the NAV root or `App/`)

| File path pattern | Area name |
|-------------------|-----------|
| `App/BCApps/src/Apps/W1/<AppName>/...` | `<AppName>` |
| `App/BCApps/src/System Application/App/<Module>/...` | `System Application / <Module>` |
| `App/BCApps/src/Business Foundation/App/<Module>/...` | `Business Foundation / <Module>` |
| `App/Layers/W1/BaseApp/<Area>/...` | `BaseApp / <Area>` (e.g., `BaseApp / Finance`) |
| `App/Apps/W1/<AppName>/...` | `<AppName>` |
| `App/Apps/<CC>/...` (2-letter country code) | `Localization / <CC>` (e.g., `Localization / DE`) |
| `App/Internal/Apps/<AppName>/...` | `Internal / <AppName>` (e.g., `Internal / ExpenseAgent`) |
| `Eng/**`, `.github/**`, `.azuredevops/**`, `build/**`, `*.ps1` | `Engineering Systems` |

### Fallback

| File path pattern | Area name |
|-------------------|-----------|
| Everything else | `(uncategorized)` |

Group changed files by area. The **primary area** is the one with the most changed files — this determines the PR title prefix.

For each area, look up the matching row in the **App / Module Reviewers** table. Use the GitHub or ADO column depending on the platform detected in Step 0.

## Step 4: Domain Detection

Scan the diff for cross-cutting domain concerns using these **built-in rules**:

### Upgrade
- **File patterns**: file name contains `Upgrade` or `Install` and ends in `.al`
- **Content keywords** (in `+` lines of diff): `Subtype = Upgrade`, `Subtype = Install`, `OnUpgradePerCompany`, `OnUpgradePerDatabase`, `OnInstallAppPerCompany`, `OnInstallAppPerDatabase`, `UpgradeTag`, `DataTransferFields`
- **Review guidance**: "Upgrade/install codeunit detected. Please verify data migration logic, UpgradeTag correctness, and backwards compatibility."

### Job Queue
- **Content keywords**: `JobQueueEntry`, `"Job Queue Entry"`, `TaskScheduler`, `StartSession`
- **Review guidance**: "Job queue / background task usage detected. Please verify error handling, retry logic, and session isolation."

### Permissions
- **File patterns**: file ends in `.PermissionSet.al`, `.PermissionSetExt.al`, `.Entitlement.al`, or path contains `/Permissions/` or `/permissions/`
- **Content keywords**: `PermissionSet`, `Entitlement`, `IncludedPermissionSets`
- **Review guidance**: "Permission set changes detected. Please verify the permissions match the feature's security requirements."

### Telemetry
- **Content keywords**: `FeatureTelemetry`, `Session.LogMessage`, `LogMessage(`, `CustomDimensions`
- **Review guidance**: "Telemetry instrumentation detected. Please verify custom dimensions, signal classification, and PII handling."

### API Pages
- **File patterns**: file name contains `API` and ends in `.Page.al`
- **Content keywords**: `PageType = API`, `APIPublisher`, `APIGroup`, `APIVersion`, `EntitySetName`
- **Review guidance**: "API page changes detected. Please verify API versioning, entity naming, and breaking change impact."

### Obsolete
- **Content keywords**: `ObsoleteState = Pending`, `ObsoleteState = Removed`, `ObsoleteReason`, `ObsoleteTag`
- **Review guidance**: "Obsolescence tags detected. Please verify the obsolete tag version, reason text, and that no removed code is still referenced."

### External HTTP
- **Content keywords**: `HttpClient`, `HttpRequestMessage`, `HttpResponseMessage`, `OAuth2`, `WebhookSubscription`
- **Review guidance**: "External HTTP calls detected. Please verify error handling, timeouts, retry logic, and OAuth flow correctness."

For each triggered domain, record:
- Which files/keywords triggered it (evidence)
- The review guidance text
- The reviewer(s) from the **Domain Reviewers** table

A single file can trigger both an app owner AND one or more domain experts.

## Step 5: Extract AI Decision Context

Review the current conversation history for decisions made during this session. Look for:

- **Architectural choices**: "I chose X instead of Y because..."
- **Trade-offs discussed**: "The alternative was... but..."
- **User confirmations**: "Yes, go with approach A"
- **Scope decisions**: "We decided not to include X in this PR"
- **Bug root cause**: "The issue was caused by..."

Format as a table:

```
| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
```

If no meaningful decisions were found (trivial change, simple bug fix), skip this section entirely.

Present the table to the user for review BEFORE including it in the PR description. The user may want to edit, add, or remove entries.

## Step 6: Detect Work Item

Check for a linked work item in this order:

1. **Skill argument**: If the user passed a number (e.g., `/create-pr 12345`), use it
2. **Branch name**: Parse `bugs/<number>-*` or `private/<user>/<number>-*` patterns → extract `<number>`
3. **Commit messages**: Scan for `AB#<number>`, `Fixes #<number>`, `#<number>`

If found:
- GitHub mode: format as `Fixes #<number>` (for GitHub issues) or `Fixes AB#<number>` (for ADO work items)
- ADO mode: format as `Fixes AB#<number>`
- **Fetch the work item title and type** to use in the Context section:
  - ADO: use `mcp__ado__wit_get_work_item` with the work item ID to get the title and work item type (Bug, User Story, Task, etc.)
  - GitHub: use `gh issue view <number> --json title,labels` to get the issue title and labels
  - If the fetch fails (permissions, network), fall back to just the ID

If NOT found:
- **Warn prominently**: "No work item linked. BCApps requires PRs to be linked to approved issues. PRs without linked issues will be rejected."
- Ask the user: "Please provide an issue/work item number, or type 'skip' to proceed without one."

## Step 7: Detect Test Changes

Scan the changed file list for test files:
- Files under `*/Test/` or `*/Test Library/` directories
- Files matching `*.Test.Codeunit.al`

If test changes exist:
- Group test files by what they test
- Include a "Test Coverage" section in the PR description

If production code changed but NO test files changed:
- Add a note: `> No test changes included in this PR.`
- This is informational, not blocking.

## Step 8: Generate Title

Rules (in order of priority):

1. **Backport**: If target branch matches `releases/*`, prepend `[releases/X.x]`
2. **Single app**: `[AppPrefix] <concise summary>` — use the primary area from Step 3
3. **Multi-app**: Use the primary area's prefix
4. **Build/infra only**: `[Build] <summary>`
5. **Keep under 72 characters**

Title prefix mappings (from git log conventions):
- Directory name is used as-is for most apps (e.g., `[Shopify]`, `[EDocument]`)
- `Quality Management` → `[Quality Mgmt.]`
- `Subscription Billing` → `[SubscriptionBilling]`
- `Production Subcontracting` → `[Subcontracting]`
- System Application modules → `[SysApp/<Module>]`
- Business Foundation modules → `[BusFound/<Module>]`
- BaseApp areas → `[BaseApp/<Area>]` (e.g., `[BaseApp/Finance]`)
- Internal apps → `[Internal/<App>]` (e.g., `[Internal/ExpenseAgent]`)
- Country localizations → `[<CC>]` (e.g., `[DE]`, `[US]`)
- Engineering Systems → `[Build]`

Generate the summary from commit messages — concise, imperative mood, describes the "what".

## Step 9: Generate PR Description

Use this template. Omit sections marked "conditional" if they don't apply.

```markdown
## Context
<!-- The purpose of this PR — what problem it solves or what feature it adds -->
<!-- Auto-populated from the linked work item title + conversation context -->
**<Work Item Type> <ID>**: <work item title>

<1-2 sentences explaining the problem or motivation, drawn from the conversation context.
For bugs: what was broken and how it manifested.
For features: what capability is being added and why.>

## Summary
- <bullet 1: what changed>
- <bullet 2: how it was changed>
- <bullet 3: key detail> (if needed)

## Key Decisions
<!-- CONDITIONAL: Omit if no AI decisions extracted in Step 5 -->
| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| <decision> | <why> | <what else was considered> |

## How to Review
<!-- One subsection per area/domain that has a reviewer assigned -->

### <AreaName> — @<reviewer>
**Files:** `<file1>`, `<file2>`
**Guidance:** <what to focus on, what changed in this area>

### <DomainName> (cross-cutting) — @<reviewer>
**Files:** `<file1>`
**Guidance:** <domain-specific review guidance from Step 4>

## Test Coverage
<!-- CONDITIONAL: Include only if test files changed -->
- `<TestCodeunit1>`: <what it tests>

<!-- CONDITIONAL: If production code changed but no tests -->
> No test changes included in this PR.

## Work Item(s)
Fixes AB#<number>
<!-- or: Fixes #<number> -->
<!-- or: No work item linked. -->

---
<sub>Generated with [Claude Code](https://claude.ai/code) using /create-pr</sub>
```

## Step 10: Present Draft and Confirm

Display the complete draft to the user:

```
## PR Draft

**Platform:** GitHub / Azure DevOps
**Target branch:** main
**Title:** [Shopify] Add contact validation on order import

**Reviewers:**
- @onbuyuka (Shopify app owner)
- @upgradeSME (Upgrade domain — ShpfyUpgrade.Codeunit.al)

**Description:**
<full markdown description>

**Inline comments planned:**
- ShpfyUpgrade.Codeunit.al → @upgradeSME: "Upgrade codeunit detected..."
```

Then ask: "Create this PR? You can: approve, edit title, edit description, add/remove reviewers, or cancel."

**Do NOT create the PR until the user explicitly approves.**

## Step 11: Create the PR

### GitHub Path

```bash
# 1. Push branch if needed
git push -u origin <branch>

# 2. Write description to temp file (avoids shell escaping issues)
# Use Write tool to create pr-body.md in current directory

# 3. Create PR
gh pr create --base main --head <branch> --title "<title>" --body-file pr-body.md

# 4. Add reviewers (collect all unique reviewers from Steps 3-4)
gh pr edit <number> --add-reviewer <user1>,<user2>

# 5. Clean up temp file
rm pr-body.md
```

### ADO Path

```
# 1. Push branch if needed
git push -u origin <branch>

# 2. Create PR
mcp__ado__repo_create_pull_request(
  repositoryId: "<repo-name>",
  project: "<project>",
  sourceRefName: "refs/heads/<branch>",
  targetRefName: "refs/heads/main",
  title: "<title>",
  description: "<body>"
)

# 3. Add reviewers
mcp__ado__repo_update_pull_request_reviewers(
  repositoryId: "<repo-name>",
  project: "<project>",
  pullRequestId: <id>,
  reviewerIds: ["<alias1>", "<alias2>"],
  action: "add"
)
```

## Step 12: Post Inline Review Comments

After the PR is created, post **one inline comment per reviewer** on their most relevant file. Pick the file with the largest diff for that reviewer, or the entry-point file for the area.

### GitHub

For each reviewer with assigned files:

```bash
gh api repos/<owner>/<repo>/pulls/<number>/comments \
  --method POST \
  -f body='@<reviewer> — <guidance text from Step 3 or Step 4>' \
  -f path='<file-path>' \
  -f subject_type='file'
```

Use `subject_type: file` to comment on the file as a whole (not a specific line). This avoids issues with line number mapping.

### ADO

For each reviewer:

```
mcp__ado__repo_create_pull_request_thread(
  repositoryId: "<repo-name>",
  project: "<project>",
  pullRequestId: <id>,
  content: "@<alias> — <guidance text>",
  filePath: "/<file-path>",
  status: "active"
)
```

### Spam prevention

- At most **one comment per reviewer**. If a reviewer matches multiple areas/domains, combine the guidance into a single comment on their most significant file.
- Do NOT post inline comments for reviewers with empty handles (no reviewer configured).
- If the PR has no reviewers assigned at all, skip this step.

## Step 13: Report

Print the final summary:

```
## PR Created

**Platform:** GitHub
**URL:** https://github.com/microsoft/BCApps/pull/1234
**Title:** [Shopify] Add contact validation on order import
**Target:** main

**Reviewers tagged:**
- @onbuyuka — Shopify app owner (inline comment on ShpfyOrder.Codeunit.al)
- @upgradeSME — Upgrade domain (inline comment on ShpfyUpgrade.Codeunit.al)

**Work Item:** Fixes AB#12345

**CODEOWNERS will also auto-assign:** @microsoft/d365-bc-app-required
```

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Missing reviewers.md | Warn, skip reviewer assignment and inline comments |
| No reviewer for a matched area | Note in PR description: "No reviewer configured for <area>" |
| No reviewer for a matched domain | Note in PR description: "No reviewer configured for <domain>" |
| No work item linked | Warn prominently, ask user to provide one or skip |
| No test changes | Informational note in description, not blocking |
| Changes span many apps | List all in "How to Review", use primary for title prefix |
| Branch not pushed | Auto-push before PR creation |
| Backport branch | Prepend `[releases/X.x]` to title |
| No AI decisions in conversation | Omit "Key Decisions" section |
| Very large diff (50+ files) | Use `--name-only` for file listing, scan `--stat` for top files, read only the largest diffs for keyword scanning |
| PR already exists for branch | Check `gh pr list --head <branch>` first. If PR exists, warn and offer to update description instead |
