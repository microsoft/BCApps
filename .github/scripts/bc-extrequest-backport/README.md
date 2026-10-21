# Extensibility request backports

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

A nonempty successful team batch creates **one Task tracking issue and one
draft release PR**, not a pair per source. The Task lists original issues with
short summaries; the PR links every included main PR and its original issues
from `closingIssuesReferences`, without duplicates. Both new objects inherit the deduplicated union of the original
issues' labels, excluding `ext-ready-to-implement`, and add `ext-backporting`.
When there are no original issue references, labels come from the source PR,
excluding its source-only `ext-backport-processed` marker.

The issue and PR share a title. Team batches use
`[Backport 29.x] [Extensibility Requests] [Team: SCM] till 2026-10-21`,
with the actual release, team and discovery date in Europe/Copenhagen. The date
is fixed for retries of the same batch.

Descriptions begin with "Backporting of extensibility requests", including
the team for a batch. Tracking Tasks list only the original issues under
`Issues:`, each with a concise summary derived from its original title. They
do not display a PR list and end with italic "Auto-generated content".
Backport PRs retain the `Issues:` and `PRs:` link lists, followed by
`Fixes #<new-backport-task-number>` and the Important AI-generated disclaimer.
They never use `Fixes` for the original issues. Source hashes and recovery
metadata remain hidden. Summaries do not require AI or model credentials.

A source is processed independently when its team is missing, ambiguous, or
inconsistent with a linked original issue's team. For example, a main PR labeled
`Team: SCM` whose original issue has `Team: Finance` does not enter either team's
batch. It retains the individual backport issue/PR behavior rather than being
silently skipped or assigned to a guessed team.

A conflicting source is also handled independently: its entire cherry-pick is
aborted, a separate needs-attention Task is created, and no partial source branch
or PR is published. Other clean sources can still form the team batch. An
already-present source gets independent no-op tracking rather than an empty
commit or PR. A team with no applied sources gets no empty batch PR.
Later sources that touch paths belonging to a failed source are also held for
attention to avoid publishing an incomplete dependency chain. This is a
conservative path check, not an inference of semantic dependencies.

For example, three clean Finance PRs create one Finance issue/PR pair; two clean
SCM PRs create one SCM pair. A third SCM PR with a conflict gets its own
needs-attention issue, not another draft PR and not a blocker for the clean SCM
batch.

Batch membership is fixed for that invocation and retained with its durable
identity. Retries must resume the same sources and target, including members
already marked processed by a partially completed publication. Later weekly
runs create new batches only for work that has not already been handled.
The 15-day selection clock is fixed at discovery, not recalculated as each
queued worker starts.

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

**Every manual run publishes.** There is no preview input or dry-run workflow
mode. Publication requires the existing protected environment and App permissions
even when scheduled creation is disabled.

Automatic failures older than 15 days need a manual single-PR run. Discovery uses
paginated REST data rather than the eventually indexed search API. More than
256 matrix requests causes an explicit failure, not a silently truncated batch.
The job summary includes team, source PRs, original issues, target and individual
outcomes. A PR is never split simply to reduce batch size.

## Publication and recovery

Independent requests retain the deterministic branch
`bc-extrequest-backport/pr-<main-pr>/<version>.x`. Team requests have their own
stable batch identity and branch, with immutable membership linking each source
PR and merge SHA. Tracking issues and PRs carry versioned identity metadata,
the pinned target and original source identities. Existing objects must have
the expected identity, repository, branches and GitHub App author. Open and
closed PRs are both checked; legacy independent requests are not replayed into
new team batches.
Branches are never force-pushed and human edits are never overwritten.

The only label this workflow adds to an original main PR is
**`ext-backport-processed`**, after it confirms that source's backport PR exists.
In a team batch, only sources actually included in that PR receive the label.
It prevents future automatic selection; it does not mean the backport merged.
No temporary, versioned, or merge-status labels are added to original PRs,
and original issues are never relabeled.

There is no daily status job or merge-lifecycle automation. Merging or closing
a backport PR does not trigger further source-label updates or closure of its
tracking Task by this workflow. Tracking issues and backport PRs still inherit
the original labels and receive `ext-backporting`.

Existing tracking identities and open/closed PR lookup prevent normal duplicate
creation. A repeated publishing run repairs missing links or the single processed
label without adding lifecycle statuses. Conflict and already-present sources
receive no processed label when no backport PR exists; their tracking records
prevent duplicate Tasks and automatic conflict retries.

API writes are not automatically retried within a run. Before creating a PR,
the workflow records a hidden publication-intent marker on its **backport
tracking issue**, not on the original PR or issues. If that marker exists but
no matching open/closed PR can be found, publication stops for operator review.
Do not clear it until the actual outcome has been established.

If Task creation fails with an uncertain response, inspect the run and existing
tracking issues before rerunning. Without temporary source labels there is no
separate durable issue-creation reservation: object discovery recovers observed
Tasks, but cannot prove the outcome of an unobserved create. Do not blindly rerun
an ambiguous create.

Conflicts create a linked independent tracking issue but no partial branch or
PR, and are not retried automatically. An open standalone conflict can be
retried by manually selecting its main PR if the target has changed; the
existing Task is reused. Outcomes recorded in an immutable team cohort remain
frozen and require manual resolution. A separate human-created resolution PR
is not adopted automatically; complete its tracking manually. Closed-unmerged
PRs and closed tracking issues are not recreated automatically.

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
writes. Run them with the repository's Pester tooling:

```powershell
Invoke-Pester .github/scripts/bc-extrequest-backport/Backport.Test.ps1
```
