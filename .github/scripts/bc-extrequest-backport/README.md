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
draft release PR**, not a pair per source. Both descriptions link every included
main PR and every original issue in its `closingIssuesReferences`, without
duplicates. Both new objects inherit the deduplicated union of the original
issues' labels, excluding `ext-ready-to-implement`, and add `ext-backporting`.
When there are no original issue references, labels come from the source PR,
excluding its source-only `ext-backport-processed` marker.

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
| Repository variable `EXT_REQ_BACKPORT_ENABLED=true` | Explicitly enables Sunday publication and daily status reconciliation. Leave unset or false until deployment is approved. |
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
# Preview all eligible team batches, using the same rules as Sunday.
gh workflow run bc-extrequest-backport.yml --repo microsoft/BCApps --ref main `
  -f dry_run=true

# Publish all eligible team batches and independent exceptions.
gh workflow run bc-extrequest-backport.yml --repo microsoft/BCApps --ref main `
  -f dry_run=false

# Preview one merged main PR independently.
gh workflow run bc-extrequest-backport.yml --repo microsoft/BCApps --ref main `
  -f source_pr=12345 -f dry_run=true

# Publish or reconcile only that selected source's existing request.
gh workflow run bc-extrequest-backport.yml --repo microsoft/BCApps --ref main `
  -f source_pr=12345 -f dry_run=false
```

Manual runs accept an **optional PR number, not an issue number**. Leave it
empty to use the automatic 15-day/category/unprocessed selection and team
grouping. Supplying one PR bypasses age, request-category and processed-label
discovery filters, but still requires a merged `main` PR, safe content, the
original target for an existing request, and duplicate prevention. A selected
source already included in a team batch refers back to that batch; it must not
create a second individual backport.

Both manual modes default to preview and require no App publication token until
`dry_run=false`. Publication still requires the existing protected environment
and App permissions even when scheduled creation is disabled.

Automatic failures older than 15 days need a manual single-PR run. Discovery uses
paginated REST data rather than the eventually indexed search API. More than
256 matrix requests causes an explicit failure, not a silently truncated batch.
The job summary includes team, source PRs, original issues, target and individual
outcomes. A PR is never split simply to reduce batch size.

## Local read-only preview

From a BCApps checkout containing this branch, use PowerShell 7.4+, Git and an
authenticated `gh` CLI. No merge to `main` is needed for local preparation.

```powershell
Import-Module ./.github/scripts/bc-extrequest-backport/Backport.psm1 -Force

# Omit -SourcePr to discover all eligible batches; supply it for one source.
$requests = @(Find-ExtRequestBackportBatches -Repository microsoft/BCApps `
  -SourcePr '11608' -BatchId ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds().ToString()))

foreach ($request in $requests) {
    $folder = Join-Path ([IO.Path]::GetTempPath()) ('backport-' + [guid]::NewGuid().ToString('N'))
    New-ExtRequestBackportBatch -Repository microsoft/BCApps `
      -RequestJson ($request | ConvertTo-Json -Depth 15 -Compress) `
      -StatePath (Join-Path $folder 'state.json')
}
```

This reads GitHub and creates temporary local results only. Do not call the
publication function using a personal `gh` token: object authorship must match
the expected GitHub App. The existing `Find-ExtRequestBackport` and
`New-ExtRequestBackport` single-PR APIs remain available for earlier local
commands.

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
and reciprocal links rather than creating another pair.

A **daily 21:25 Europe/Copenhagen** reconciliation updates existing backports
without creating new backport batches. It also runs after Sunday creation.
When a team PR merges, it closes that batch's issue and updates every included
main PR, even outside the 15-day discovery window. Conflicted/excluded sources
are not marked merged with the clean batch. Independent requests are reconciled
as before. Release-targeted PRs do not automatically close GitHub issues, so
reconciliation explicitly closes the tracking Task.

API writes are not automatically retried. If issue or PR creation has an
uncertain outcome, its intent label remains. A later run first discovers the
actual objects. If an intent exists but its object cannot be found, publication
stops for operator reconciliation. Before removing an intent label, inspect
all open/closed tracking objects and the deterministic branch and establish
whether creation occurred. Never clear labels simply to bypass duplicate checks.

Conflicts create a linked independent tracking issue but no partial branch or
PR, and are not retried automatically. Rerun that main PR manually if the target
has changed. A separate human-created conflict-resolution PR is not adopted
automatically; complete its tracking/status manually. Closed-unmerged PRs and
closed tracking issues are not recreated automatically.

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
