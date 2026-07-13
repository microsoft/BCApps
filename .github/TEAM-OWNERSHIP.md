# Team ownership automation

BCApps delegates team classification to the private `microsoft/BCAppsTriage` repository and remains the only repository that writes BCApps labels. This integration manages team ownership only; it does not assign a person or implement "whose turn."

## Labels

Exactly one team label is expected on every open issue and pull request:

| Label | Color | Meaning |
| --- | --- | --- |
| `Finance` | `1d76db` | Owned by the Finance team |
| `SCM` | `60AFDE` | Owned by the SCM team |
| `Integration` | `DC57FE` | Owned by the Integration team |
| `Other` | `6E7781` | Not mapped to the three named teams |

Two non-team labels control or expose automation state:

| Label | Color | Meaning |
| --- | --- | --- |
| `Ownership: Manual` | `FBCA04` | Preserve a maintainer-selected team |
| `Ownership: Needs Review` | `D93F0B` | The automated result is `Other` or low confidence, or a manual override is invalid |

The consumer creates missing labels and corrects their descriptions/colors before a live result is applied. `Ownership: Needs Review` does not count as a team label.

## Lifecycle

`.github/workflows/ownership-classification.yml` classifies:

- issues on open, reopen, and edit;
- pull requests on open, reopen, edit, synchronize, and ready-for-review; and
- subjects when the manual override is removed.

It uses `pull_request_target` for pull requests and checks out only the BCApps default branch. It never checks out or executes pull request head code. Fork pull requests therefore cannot read the App private key.

The reusable workflow mints a short-lived GitHub App token scoped only to `microsoft/BCAppsTriage`, dispatches its `ownership-classification.yml`, waits for the correlated run, and downloads `ownership-result/ownership-result.json`. The App token cannot write BCApps. After strict schema and subject-identity validation, the BCApps `GITHUB_TOKEN` applies the labels.

Producer v1 bounds results to 64 MiB of UTF-8 JSON, at most 6,000 evidence entries, 1,024 characters per evidence string field, and a 1,000-character reason. When verbose evidence would exceed 64 MiB, the producer deterministically compacts it and includes bounded API evidence describing omitted entries. The consumer enforces the same limits before applying labels.

A required part of the producer contract is a workflow `run-name` containing `[${{ inputs.correlation_token }}]`. The consumer uses that marker to locate the unique dispatched run before it validates the same token inside the downloaded result.

A missing, failed, oversized, malformed, or mismatched result fails the run before any subject-label mutation. Valid application adds the selected team before removing competing team labels, preserves all unrelated labels, and verifies the final exact-one state with bounded retries.

## Manual override

To set ownership manually:

1. Add `Ownership: Manual`.
2. Leave exactly one of `Finance`, `SCM`, `Integration`, or `Other`.
3. Check the resulting ownership workflow run. An override with zero or multiple team labels fails visibly and receives `Ownership: Needs Review`; automation does not choose or remove a team under the override.
4. Remove `Ownership: Needs Review` after resolving an invalid override if it is no longer useful.

Team-label changes while the override exists trigger another audit. To resume automation, remove `Ownership: Manual`; removal triggers a fresh classification. Automation re-checks the override immediately before writes, so an override added while the producer is running prevents the result from being applied.

## Reconciliation and backfill

`.github/workflows/ownership-reconciliation.yml` runs hourly. It:

- scans open issues and pull requests with GraphQL cursors;
- restores a small checkpoint artifact and rotates through both subject kinds;
- processes at most 25 subjects per run with at most five producer runs in parallel;
- audits overridden subjects; and
- reclassifies every non-overridden subject in each cycle.

Reclassifying the full bounded cycle repairs missing/conflicting labels and refreshes decisions after content changes even if a lifecycle event was missed. Current inventory counts and the next cursor are written to the run summary.

For an operator backfill, run **Team Ownership Reconciliation** manually:

1. Choose `issue` or `pull_request`.
2. Set `max_items` from 1 through 100.
3. Keep `dry_run` enabled for the first batch.
4. Use the `next position` cursor from the summary as the next run's optional `cursor`.
5. Disable `dry_run` only after reviewing the proposed decisions.

Manual runs do not advance the scheduled checkpoint. Dry runs do not create labels, mutate subjects, or update checkpoint state.

## Observability and failures

Each classification summary includes subject, team, source, confidence, bounded reason, and application status. Reconciliation inventory summaries include selected, exact-one, missing, conflicting, overridden, and deferred counts. Raw evidence and secrets are never logged.

Failures remain visible as failed workflow runs and summaries. Reconciliation eventually retries failed subjects after the cursor completes its cycle. If an invalid manual override is the cause, maintainers must correct its team labels.

## Deployment order

The producer from `microsoft/BCAppsTriage` commit `5db9ee1` must be merged and deployed on that repository's default branch before the BCApps consumer is merged.

The BCApps change enables the ownership consumer and removes only the legacy AI triage team-label write in the same default-branch revision. AI triage continues posting comments and setting issue types. Before that revision AI triage still covers new issues; after it, the ownership workflow is authoritative. Run a small dry run and limited live reconciliation batch after deployment, then let the hourly sweep complete the migration.
