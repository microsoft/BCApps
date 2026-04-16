# Automated Parent-Child Linking of ADO Work Items for Backported PRs

## Problem

When a bug is fixed on `main` and backported to a release branch (e.g., `releases/28.x`), two separate Azure DevOps work items are created — one for the master fix and one for the release fix. Today, developers must **manually** open ADO and create a Parent-Child link between them. This is tedious, error-prone, and often forgotten.

## Solution

A GitHub Actions workflow (`link-backport-workitems.yml`) that **automatically** detects backport PRs on release branches and creates a Parent-Child link between the corresponding ADO work items.

## How It Works

### The Data Flow

```
PR #7734 (releases/28.x)             PR #7733 (main)
┌──────────────────────────┐         ┌──────────────────────────┐
│ Fixes #7732              │         │ Fixes #7732              │
│ Fixes AB#631297          │         │ Fixes AB#631296          │
└────────────┬─────────────┘         └────────────┬─────────────┘
             │                                    │
             ▼                                    ▼
       RELEASE_WI = 631297               MASTER_WI = 631296
             │                                    │
             └──────────── ADO REST API ──────────┘
                              │
                    631297 (child) → 631296 (parent)
```

### Step-by-Step

| Step | Action | Details |
|------|--------|---------|
| **1. Parse** | Extract references from the release PR | Finds `AB#631297` (release work item) and `Fixes #7732` (linked issue) |
| **2. Resolve** | Follow the issue to find the main PR | Queries the GitHub Timeline API for issue #7732, discovers PR #7733 cross-references it, extracts `AB#631296` from PR #7733's body |
| **3. Link** | Create Parent-Child relation in ADO | PATCHes work item 631297 with a `System.LinkTypes.Hierarchy-Reverse` relation pointing to 631296 |

### Supported PR Description Patterns

The workflow recognizes two patterns for finding the original PR/issue:

| Pattern | Source | Example |
|---------|--------|---------|
| `backports #NNN` / `backport of #NNN` | `CrossBranchPorting.psm1` (automated backports) | `"This pull request backports #7729 to releases/28.x"` |
| `Fixes #NNN` / `Closes #NNN` | Manual PRs | `"Fixes #7732"` |

Both patterns are checked. The backport pattern takes priority if both are present.

### Safety Guarantees

| Check | Description |
|-------|-------------|
| **Idempotent** | Checks if the parent link already exists before creating. Safe to re-run. |
| **Self-link guard** | Skips if the master and release work item IDs are the same. |
| **Work item validation** | Verifies the parent work item exists before attempting to link. |
| **Graceful degradation** | If the original PR/issue has no `AB#` reference, the workflow logs a warning and exits cleanly. |

## Trigger Conditions

The workflow runs when:

| Event | Condition |
|-------|-----------|
| `pull_request_target: opened` | A new PR is opened against `releases/**` |
| `pull_request_target: edited` | A PR description is edited (e.g., `AB#` added later) |
| `pull_request_target: labeled` | A label is applied (e.g., "Linked" from the existing `WorkitemValidation` workflow) |
| `workflow_dispatch` | Manual trigger with a `pr_number` input (for testing) |

The job only runs if the PR body contains `AB#` (or if triggered manually via `workflow_dispatch`).

## Files

| File | Purpose |
|------|---------|
| `.github/workflows/link-backport-workitems.yml` | The GitHub Actions workflow that runs automatically |
| `demo-link-backport.ps1` | Local PowerShell demo script for testing without deploying |

## Prerequisites

### Repository Secret: `ADO_PAT`

The workflow requires an Azure DevOps Personal Access Token stored as the GitHub repository secret `ADO_PAT`.

**Creating the PAT:**
1. Go to https://dev.azure.com/dynamicssmb2 → Profile icon → **Personal access tokens**
2. Click **+ New Token**
3. Organization: `dynamicssmb2`
4. Scopes: **Work Items → Read & Write**
5. Copy the token and add it as a repository secret named `ADO_PAT`

### Workflow File on Release Branches

Since the workflow uses `pull_request_target`, the workflow file must exist **on the target branch** (e.g., `releases/28.x`). New branches cut from `main` will inherit it automatically. For existing release branches, cherry-pick the file:

```bash
git checkout releases/28.x
git checkout main -- .github/workflows/link-backport-workitems.yml
git commit -m "Add link-backport-workitems workflow"
git push origin releases/28.x
```

## Demo (No Merge Required)

### Prerequisites
- `gh` CLI installed and authenticated (`gh auth status`)
- Access to the `microsoft/BCApps` repository

### Demo 1 — Dry Run (show the logic, no ADO changes)

```powershell
.\demo-link-backport.ps1 -ReleasePR 7734 -DryRun
```

**Expected output:**
```
========================================
 Backport Work Item Linker — Demo
========================================

[Step 1] Fetching PR #7734 description...
  RELEASE_WI = 631297
  ORIG_REF = 7732 (from Fixes # pattern)

[Step 2] Resolving master work item from #7732...
  No AB# on #7732 directly. Searching issue timeline...
  Found cross-referenced PRs: 7733, 7734
  Checking PR #7733...
  Found AB#631296 on PR #7733

========================================
 RESULT
========================================
  Release PR:     #7734
  Release WI:     AB#631297 (child)
  Master WI:      AB#631296 (parent)
  ADO Link:       631297 -> 631296 (Parent-Child)

  [DRY RUN] Would call ADO REST API:
  PATCH .../workitems/631297?api-version=7.1
```

### Demo 2 — Live Run (creates the actual ADO link)

```powershell
.\demo-link-backport.ps1 -ReleasePR 7734
```

Enter your ADO PAT when prompted. Then verify in Azure DevOps:
- Open [AB#631297](https://dev.azure.com/dynamicssmb2/Dynamics%20SMB/_workitems/edit/631297) → **Related Work** section should show **Parent: AB#631296**
- Open [AB#631296](https://dev.azure.com/dynamicssmb2/Dynamics%20SMB/_workitems/edit/631296) → **Related Work** section should show **Child: AB#631297**

### Demo 3 — Idempotency (re-run is safe)

```powershell
.\demo-link-backport.ps1 -ReleasePR 7734
```

**Expected output:** `"Parent link already exists. Nothing to do."`

## Architecture: How It Fits the Existing Workflow

```
Developer opens PR on main ──→ WorkitemValidation.yaml
  │                               ├─ Validates issues
  │                               ├─ Links AB# from issue to PR
  │                               └─ Adds "Linked" label
  │
  ├─ PR merged to main
  │
  ├─ Developer runs CrossBranchPorting (New-BCAppsBackport)
  │   └─ Creates backport PR on releases/28.x
  │       body: "backports #NNN\nFixes AB#<release_WI>"
  │
  └─ OR developer manually creates release PR
      body: "Fixes #NNN\nFixes AB#<release_WI>"
              │
              ▼
     link-backport-workitems.yml ◄── NEW
       ├─ Parses release PR
       ├─ Resolves master WI via issue timeline
       └─ Creates Parent-Child link in ADO
```

## ADO API Details

The workflow uses the [Azure DevOps Work Item Tracking REST API v7.1](https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/work-items/update) to add a relation:

```
PATCH https://dev.azure.com/dynamicssmb2/Dynamics%20SMB/_apis/wit/workitems/{childId}?api-version=7.1
Content-Type: application/json-patch+json

[
  {
    "op": "add",
    "path": "/relations/-",
    "value": {
      "rel": "System.LinkTypes.Hierarchy-Reverse",
      "url": "https://dev.azure.com/dynamicssmb2/Dynamics%20SMB/_apis/wit/workItems/{parentId}",
      "attributes": {
        "comment": "Auto-linked by link-backport-workitems"
      }
    }
  }
]
```

- `Hierarchy-Reverse` = "set Parent on this item"
- `Hierarchy-Forward` = "add Child to this item"
- Both produce the same bidirectional Parent-Child link

## Rollout Plan

1. **Merge PR #7733** to `main` (includes `link-backport-workitems.yml` and `demo-link-backport.ps1`)
2. **Configure `ADO_PAT`** as a GitHub repository secret
3. **Cherry-pick** the workflow file to active release branches (`releases/28.x`, etc.)
4. **Delete** `demo-link-backport.ps1` from the repository (it's only for demo/testing)
