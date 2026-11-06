# Extensibility request backports

For a short explanation of everyday use and common scenarios, see the
[user guide](USER-GUIDE.md). This document covers configuration and technical recovery.

`bc-extrequest-backport.yml` creates backports on **Sunday at 21:10
Europe/Copenhagen**. It scans the rolling last **15 days** for PRs merged into
`main`, with no fixed start date. The overlapping window allows a later weekly
run to catch work missed by a previous run. It includes
`event-request`, `request-for-external`, or both, but rejects other request
categories (`enum-request`, `extensibility-enhancement`, `extensibility-bug`,
other `*-request` / `request-for-*` labels). Linked source issues must also have
only the allowed request categories. Unrelated labels, including team labels,
do not prevent selection. Original main PRs carrying `ext-backport-processed` are
excluded from automatic discovery.

## Team batches and individual exceptions

Team membership comes from the **main PR's `Team:` label**. Eligible PRs for
the same team and target are processed oldest first in one cumulative Git
checkout, keeping one provenance commit per source. The entire source PR is
considered, including every original issue already combined in a main-branch
team PR.

A nonempty successful team batch creates **one draft release PR**. All batches
and individual requests for the same target branch and milestone share
**one Task tracking issue**, across teams, weekly iterations and manual runs.

The shared issue uses this title:

```text
[Backporting][releases/29.x][Extensibility Requests][Version 29.1]
```

Its description contains a managed table with original issue links and short
title-derived summaries, original main PR links, source teams and backport PR
links. Existing rows are retained and new rows are deduplicated. A backport PR
covering several original issues has several rows pointing to that same PR.
Sources without a linked original issue are shown explicitly rather than
inventing an issue.
The issue ends with italic "Auto-generated content".

Backport PR titles remain independent of the shared issue title. Team PRs use
`[Backport 29.x] [Extensibility Requests] [Team: SCM] till 2026-10-21`,
with the actual release, team and discovery date in Europe/Copenhagen. The date
is fixed for retries of the same batch. Individual PRs retain their source-based
title. PR descriptions retain the original `Issues:` and `PRs:` lists,
`Fixes #<shared-milestone-task-number>` and the Important AI-generated disclaimer.
They never use `Fixes` for the original issues. Source hashes and recovery
metadata remain hidden; summaries do not require AI or model credentials.

Backport PR labels inherit the original issue label union, excluding
`ext-ready-to-implement`, plus `ext-backporting`. When there are no original
issues, labels come from the main PR, excluding `ext-backport-processed`.
The shared Task also excludes `Team:*` and `Ownership:*`: its source teams are
recorded in table rows instead. Generated `ext-backporting` issues are excluded
from ownership classification; backport PR ownership remains unchanged.

A source is processed independently when its team is missing, ambiguous, or
inconsistent with a linked original issue's team. For example, a main PR labeled
`Team: SCM` whose original issue has `Team: Finance` does not enter either team's
batch. It retains individual PR preparation while using the same milestone
tracker, rather than being silently skipped or assigned to a guessed team.

A conflicting source is also handled independently: its entire cherry-pick is
aborted, its row records the need for manual resolution, and no partial source
branch or PR is published. Other clean sources can still form the team batch.
Already-present sources are recorded in the same shared tracker without empty
commits or PRs. Neither outcome creates another Task or marks its source PR
processed without a real backport PR. A team with no applied sources gets no
empty batch PR.
Later sources that touch paths belonging to a failed source are also held for
attention to avoid publishing an incomplete dependency chain. This is a
conservative path check, not an inference of semantic dependencies.

For example, three clean Finance PRs create one Finance PR; two clean
SCM PRs create one SCM PR. Both PRs reference the same milestone Task. A third
SCM PR with a conflict gets a manual-attention row in that Task, not another
issue or draft PR and not a blocker for the clean SCM batch.

Batch membership is fixed for that invocation and retained with its durable
identity. Retries must resume the same sources and target, including members
already marked processed by a partially completed publication. Later weekly
runs create new batches only for work that has not already been handled.
The 15-day selection clock is fixed at discovery, not recalculated as each
queued worker starts.

## Milestone selection and tracker lifetime

The milestone is selected using the same setting as BCApps' Work Item
Validation workflow: read `repoVersion` from
`.github/AL-Go-Settings.json` on the selected target branch, then find the exact
existing milestone named `Version <repoVersion>`. For example,
`releases/29.x` configured as `29.1` uses `Version 29.1`, even if future milestones
such as `Version 29.2` are already open. The workflow does not select the highest
open milestone or create milestones automatically.

New work for another version gets another tracking Task. Existing durable
requests retain their original target and milestone. Missing, ambiguous or
closed milestones stop publication rather than selecting a different version.

If the matching tracking issue is closed while its milestone is still open,
adding more work reopens that same issue. It never creates a replacement Task
for the same branch/milestone. A closed milestone is never reopened.
The shared tracker is not closed when an individual backport PR merges.

## Configuration

Use the existing `extensibility-agent` environment and GitHub App:

| Setting | Purpose |
| --- | --- |
| Repository variable `EXT_REQ_BACKPORT_ENABLED=true` | Explicitly enables Sunday publication. Leave unset or false until deployment is approved. |
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
participate. Once a tracking issue exists, that request retains its
original target even when a newer release branch appears.

## Manual operation

Run from `main` after the workflow has merged:

```powershell
# Publish all eligible team batches and independent exceptions.
gh workflow run bc-extrequest-backport.yml --repo microsoft/BCApps --ref main

# Publish one merged main PR, or recover its existing backport.
gh workflow run bc-extrequest-backport.yml --repo microsoft/BCApps --ref main `
  -f source_pr=12345
```

Manual runs accept an **optional PR number, not an issue number**. Leave it
empty to use the automatic 15-day/category/unprocessed selection and team
grouping. Supplying one PR bypasses age, request-category and processed-label
discovery filters, but still requires a merged `main` PR, safe content, the
original target for an existing request, and duplicate prevention. A selected
source already included in a team batch refers back to that batch; it must not
create a second individual backport.

Both manual forms reuse the same milestone Task as scheduled runs. Manual
selection does not create a separate tracking issue.

**Every manual run publishes.** There is no preview input or dry-run workflow
mode. Publication requires the existing protected environment and App permissions
even when scheduled creation is disabled.

Automatic failures older than 15 days need a manual single-PR run. Discovery uses
paginated REST data rather than the eventually indexed search API. More than
256 matrix requests causes an explicit failure, not a silently truncated batch.
The job summary includes team, source PRs, original issues, target and individual
outcomes. A PR is never split simply to reduce batch size.

## Publication and recovery

New backport branches use these names:

| Request | Branch example |
| --- | --- |
| Single original main PR 11166 | `bc-extrequest-backport/backport_11166` |
| Weekly SCM batch | `bc-extrequest-backport/scm-2026-10-21` |
| Weekly Finance batch | `bc-extrequest-backport/finance-2026-10-21` |

The single-request number is the **original PR number**, not an issue number.
Team names use a lowercase branch-safe slug; the date is the discovery date in
Europe/Copenhagen. If another backport already uses or reserves the name, add
`-2`, `-3`, and so on. The chosen name is retained with the immutable cohort,
so a retry uses the same branch even on a different day. A branch that changes
unexpectedly is never overwritten.

Existing requests keep their original branches, including older
`pr-<main-pr>/<version>.x`, `single-<main-pr>` and `team-<hash>` names under
`bc-extrequest-backport/`. They are not renamed or recreated under the new naming
scheme.

Team requests retain a stable batch identity, separate from the readable branch
name, with immutable membership linking each source PR and merge SHA.
The shared Task is a mutable milestone index, not a single
immutable cohort. Per-request journal records preserve membership, outcomes,
source identities and publication intent separately from the accumulating
table. Existing objects must have
the expected identity, repository, branches and GitHub App author. Open and
closed PRs are both checked; legacy independent requests are not replayed into
new team batches.
Branches are never force-pushed and human edits are never overwritten.
New references use create-only publication: a late collision stops rather than
updating an existing branch or silently changing the cohort's pinned name.

The only label this workflow adds to an original main PR is
**`ext-backport-processed`**, after it confirms that source's backport PR exists.
In a team batch, only sources actually included in that PR receive the label.
It prevents future automatic selection; it does not mean the backport merged.
No temporary, versioned, or merge-status labels are added to original PRs,
and original issues are never relabeled.

There is no daily status job or source merge-lifecycle automation. Merging or
closing a backport PR does not trigger further source-label updates or closure
of the shared tracking Task by this workflow.

Existing tracking identities and open/closed PR lookup prevent normal duplicate
creation. A repeated publishing run repairs missing links or the single processed
label without adding lifecycle statuses. Conflict and already-present sources
receive no processed label when no backport PR exists; their journal records
prevent duplicate rows and automatic conflict retries.

API writes are not automatically retried within a run. Before creating a PR,
the workflow records publication intent in its per-request journal, not on the
original PR or issues. If intent exists but no matching open/closed PR can be
found, publication stops for operator review.
Do not clear it until the actual outcome has been established.

If Task or journal creation fails with an uncertain response, inspect the run
and existing tracking objects before rerunning. Without temporary source labels
there is no separate durable creation reservation: object discovery recovers
observed records, but cannot prove the outcome of an unobserved create.
Do not blindly rerun an ambiguous create. Oversized complete tables or journal
records fail explicitly rather than truncating history or splitting the tracker
into extra issues.

Conflicts create a row in the shared tracker, but no partial branch or PR, and
are not retried automatically. A manual selected-PR run can retry a standalone
conflict against a changed target, reusing the tracker through a validated
journal revision. Outcomes recorded in an immutable team cohort remain frozen
and require manual resolution. A separate human-created
resolution PR is not adopted automatically; complete its tracking manually.
Closed-unmerged PRs are not recreated automatically. Legacy App-authored
independent tracking records remain recognizable; human-authored demonstration
issues and PRs are not silently adopted into production tracking.

## Content boundaries

The worker uses native Git, not the issue implementation skill and not an AI
resolver. It adapts the separation of preparation/publication, source identity,
already-applied proof and conservative failure behavior used by the BCAppsTest
backport pilot; it does not import that pilot's label admission, private
deployment identities or experimental AI workflow.

BCApps currently allows squash merges only. A source commit must have one
parent and be on `main`. Only regular, non-executable files under `src/` are
admitted, at most 250 paths per source. Renames are handled as delete/add pairs.
Changes to workflow/build instructions, symlinks, submodules and unsafe paths
stop before publication. A temporary sparse Git checkout contains only affected paths.
Global/system Git config, hooks, filters and repository normalization are
disabled, and source content is never executed. A conflict aborts the complete
cherry-pick without discarding earlier clean sources. Publication verifies the
prepared chain, membership and resulting tree and reads back the pushed ref
before creating the PR.

Normal release CI and developer review remain mandatory. The workflow never
merges a backport PR. Its offline Pester tests run for relevant workflow PRs and
before discovery; they also exercise real local Git cherry-picks without remote
writes and execute the ownership workflow's preflight against mocked GitHub
APIs. Changes to either workflow or its regression tests trigger this targeted
suite. Run it with the repository's Pester tooling:

```powershell
Import-Module Pester -RequiredVersion 5.7.1
Invoke-Pester -Path @(
    '.github/scripts/bc-extrequest-backport/Backport.Test.ps1'
    'build/scripts/tests/OwnershipClassification.Test.ps1'
)
```
