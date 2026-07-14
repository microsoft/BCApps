# Team ownership automation

BCApps delegates classification to `microsoft/BCAppsTriage` and uses its own `GITHUB_TOKEN` to maintain exactly one team label: `Finance`, `SCM`, `Integration`, or `Other`. This automation does not assign an individual.

## Architecture and security

`ownership-classification.yml` handles open issue and pull request lifecycle events. Pull requests use `pull_request_target`; no workflow checks out or executes PR-head code. Trusted default-branch workflow code mints a short-lived GitHub App token scoped only to BCAppsTriage, dispatches its producer on `main`, waits for the exact correlation marker, requires success, and downloads the fixed `ownership-result` artifact.

Before any write, the consumer requires an artifact of at most 67,108,864 UTF-8 bytes and validates only consumed v1 fields: schema version, correlation and subject identity, team, confidence, source, and a meaningful bounded reason. Producer evidence is neither inspected nor logged.

The selected team is added before competing team labels are removed. Unrelated labels are preserved and the final exact-one state is re-fetched and retried up to three times.

## Labels and manual override

`Ownership: Manual` preserves a maintainer-selected team. It is valid only with exactly one team label. Invalid overrides keep their team labels, receive `Ownership: Needs Review`, and fail visibly. Remove `Ownership: Manual` to trigger fresh classification.

Automated `Other` or low-confidence decisions receive `Ownership: Needs Review`; a valid non-`Other`, non-low decision removes it.

## Reconciliation

`ownership-reconciliation.yml` runs hourly and can be started manually in dry-run mode. It searches only open issues and PRs with zero or multiple team labels. Invalid manual overrides are audited in a separate bounded search, receive Needs Review, and fail the run without blocking later candidates. Audits and classifications together are limited to 25 scheduled candidates or 1-100 manually requested candidates, with five classification jobs in parallel. Successfully fixed candidates leave subsequent searches, allowing later runs to progress without cursor artifacts. Correctly labeled subjects are not reclassified; lifecycle events refresh stale decisions.

## One-time label provisioning

Run these commands once before enabling the workflows:

```powershell
gh label create "Finance" --repo microsoft/BCApps --color 1d76db --description "Requests owned by the Finance team" --force
gh label create "SCM" --repo microsoft/BCApps --color 60AFDE --description "Requests owned by the SCM team" --force
gh label create "Integration" --repo microsoft/BCApps --color DC57FE --description "Requests owned by the Integration team" --force
gh label create "Other" --repo microsoft/BCApps --color 6E7781 --description "Requests not mapped to Finance, SCM, or Integration" --force
gh label create "Ownership: Manual" --repo microsoft/BCApps --color FBCA04 --description "Preserve the manually selected team ownership" --force
gh label create "Ownership: Needs Review" --repo microsoft/BCApps --color D93F0B --description "Ownership is Other, low confidence, or needs manual correction" --force
```

The workflows verify these names and fail clearly when provisioning is incomplete; they never create or update repository labels.

## Deployment

1. Merge and deploy [microsoft/BCAppsTriage#39](https://github.com/microsoft/BCAppsTriage/pull/39) to `main`.
2. Provision the six labels above.
3. Confirm the BCApps `triage` environment contains the App private key, App ID variable, and default-branch policy.
4. Merge the BCApps consumer, run a small reconciliation dry run, then a limited live batch.

The same BCApps revision enables ownership automation and removes only AI triage's team-label write. AI triage comments and issue-type updates remain unchanged.
