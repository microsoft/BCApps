# Extensibility request backports

`bc-extrequest-backport.yml` runs at 21:10 Europe/Copenhagen. It scans the rolling
last seven days for PRs merged into `main`, with no fixed start date. It includes
`event-request`, `request-for-external`, or both, but rejects other request
categories (`enum-request`, `extensibility-enhancement`, `extensibility-bug`,
other `*-request` / `request-for-*` labels). Linked source issues must also have
only the allowed request categories. Unrelated labels, including team labels,
do not prevent selection. Original main PRs carrying `ext-backport-processed` are
excluded from automatic discovery.

The entire merged PR is backported, including all issues in a team batch.
Each source PR gets one tracking issue of type **Task** and, when the complete
change applies cleanly, one **draft** release PR. Both descriptions link the
main PR and every issue in its `closingIssuesReferences`. Both new objects
inherit the deduplicated union of the original issues' labels, excluding only
`ext-ready-to-implement`, and add `ext-backporting`. For a manually selected PR
with no closing issue references, labels come from that PR instead, excluding
the source-only `ext-backport-processed` marker.

This is not one combined backport per day: three eligible main PRs produce
three tracking issues and three draft backport PRs, assuming all apply cleanly.
A single team-batch main PR still produces only one issue/PR pair.

## Configuration

Use the existing `extensibility-agent` environment and GitHub App:

| Setting | Purpose |
| --- | --- |
| Repository variable `EXT_REQ_BACKPORT_ENABLED=true` | Explicitly enables scheduled publication. Leave unset or false until deployment is approved. |
| Optional repository variable `EXT_REQ_BACKPORT_TARGET_BRANCH` | Overrides automatic selection, for example `releases/29.x`. Must name an existing `releases/<number>.x` branch. |
| Environment variable `EXTENSIBILITY_CLIENT_ID` | Existing GitHub App client ID. |
| Environment secret `EXTENSIBILITY_TRIAGE_APP_PRIVATE_KEY` | Existing App private key. |

The App installation must allow **Contents: write**, **Issues: write** and
**Pull requests: write** for BCApps. The workflow's own token is read-only.
The App token is minted only after preparation, is scoped to BCApps, and is
revoked by `actions/create-github-app-token` at job completion.
No Copilot token, Azure login or model access is needed.

Without an override, branches are paginated and the highest numerical
`releases/<number>.x` is selected. Patch releases and preview names do not
participate. Once an issue or source status exists, that request retains its
original target even when a newer release branch appears.

## Manual operation

Run from `main` after the workflow has merged:

```powershell
# Read-only preview; no App token or remote writes.
gh workflow run bc-extrequest-backport.yml --repo microsoft/BCApps --ref main `
  -f source_pr=12345 -f dry_run=true

# Publish the backport issue and draft PR.
gh workflow run bc-extrequest-backport.yml --repo microsoft/BCApps --ref main `
  -f source_pr=12345 -f dry_run=false
```

Manual runs accept a **PR number, not an issue number**. They bypass age,
request-category and processed-label discovery filters but still require a
merged `main` PR, safe content, the original target for an existing request,
and duplicate prevention. A processed source can be reconciled, not duplicated.

Automatic failures older than seven days need a manual run. Discovery uses
paginated REST data rather than the eventually indexed search API. More than
256 eligible PRs causes an explicit failure, not a silently truncated batch.
The job summary includes the selected target, source issues and outcome.

## Publication and recovery

The deterministic branch is `bc-extrequest-backport/pr-<main-pr>/<version>.x`.
Tracking issues and PRs carry a versioned marker with the main PR, target and
source merge SHA. Existing objects must have the expected marker, repository,
branches and GitHub App author. Open and closed PRs are both checked.
Branches are never force-pushed and human edits are never overwritten.

Source PR status labels are created as needed:

| Label | Meaning |
| --- | --- |
| `ext-backport-processed` | Added to the original main PR once a backport PR exists, a conflict is tracked, or the patch is proven already present. Excludes that main PR from future automatic discovery; does not imply the backport merged. |
| `ext-backport-created:29.x` | The corresponding backport PR exists. |
| `ext-backport-needs-attention:29.x` | The source conflicts or its backport PR was closed without merging. |
| `ext-backport-merged:29.x` | The backport PR merged. |
| `ext-backport-already-present:29.x` | The entire patch is already present; the issue closes without an empty PR. |
| `ext-backport-pending:29.x` | Durable intent to create the tracking issue. |
| `ext-backport-publishing:29.x` | Durable intent to create the backport PR. |

The version suffix follows the pinned release. `ext-backport-processed` is the
automatic source filter; `ext-backporting` identifies the backport issue and PR.
Versioned source labels give the detailed status. Labels
are not the only duplicate check. A retry repairs missing issue/PR labels
and reciprocal links rather than creating another pair. A scheduled
reconciliation also handles older open tracking issues: when their release PR
merges, it closes the issue and marks the source PR, even outside the seven-day
discovery window. Release-targeted PRs do not automatically close GitHub issues,
so reconciliation explicitly closes the new Task.

API writes are not automatically retried. If issue or PR creation has an
uncertain outcome, its intent label remains. A later run first discovers the
actual objects. If an intent exists but its object cannot be found, publication
stops for operator reconciliation. Before removing an intent label, inspect
all open/closed tracking objects and the deterministic branch and establish
whether creation occurred. Never clear labels simply to bypass duplicate checks.

Conflicts create a linked tracking issue but no partial branch or PR, and are
not retried automatically. Resolve the backport manually using the recorded
source/target identity, or rerun that main PR manually if the target has changed.
Closed-unmerged PRs and closed tracking issues are not recreated automatically.

## Content boundaries

The worker uses native Git, not the issue implementation skill and not an AI
resolver. It adapts the separation of preparation/publication, source identity,
already-applied proof and conservative failure behavior used by the BCAppsTest
backport pilot; it does not import that pilot's label admission, private
deployment identities or experimental AI workflow.

BCApps currently allows squash merges only. A source commit must have one
parent and be on `main`. Only regular, non-executable files under `src/` are
admitted, at most 250 paths. Renames are handled as delete/add pairs. Changes to
workflow/build instructions, symlinks, submodules and unsafe paths stop before
publication. A temporary sparse Git checkout contains only affected paths.
Global/system Git config, hooks, filters and repository normalization are
disabled, and source content is never executed. A conflict aborts the complete
cherry-pick. Publication verifies the prepared commit/tree/parent and reads back
the pushed ref before creating the PR.

Normal release CI and developer review remain mandatory. The workflow never
merges a backport PR. Its offline Pester tests run for relevant workflow PRs and
before discovery; they also exercise real local Git cherry-picks without remote
writes. Run them with the repository's Pester tooling:

```powershell
Invoke-Pester .github/scripts/bc-extrequest-backport/Backport.Test.ps1
```
