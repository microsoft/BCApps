# Whose turn labels

Every open issue and pull request has exactly one label showing who should act
next:

| Label | Description | Color |
| --- | --- | --- |
| `Turn: Microsoft` | Next action is with the BCApps team. | `0E8A16` |
| `Turn: Partner` | Next action is with the partner or contributor. | `1D76DB` |
| `Turn: Blocked` | No action is expected until an explicit blocker is resolved. | `D73A4A` |

## Behavior

New and reopened issues and non-draft pull requests start with Microsoft. Draft
pull requests start with the partner. A partner comment, edit, review, or new
non-draft commit hands the turn to Microsoft. A Microsoft team comment, inline
comment, or review hands it to the partner; an approval returns it to Microsoft
only when no Microsoft team reviewer's latest review still requests changes.
Bot comments and reviews do not move the turn.

A human can select any turn label directly. `Turn: Blocked` is a sticky manual
override: ordinary activity cannot replace it, but selecting either other turn
label explicitly unblocks the item. Malformed states resolve to blocked first,
then an existing sole turn label, then partner for a draft pull request or
Microsoft for any other open item. Unrelated labels are preserved.

Microsoft actors are humans with effective write, maintain, or admin repository
permission. Organization membership or collaborator association alone is not
enough.

## Provision and operate

Provision the labels once before enabling the workflow:

```bash
gh label create "Turn: Microsoft" --repo microsoft/BCApps --description "Next action is with the BCApps team." --color "0E8A16"
gh label create "Turn: Partner" --repo microsoft/BCApps --description "Next action is with the partner or contributor." --color "1D76DB"
gh label create "Turn: Blocked" --repo microsoft/BCApps --description "No action is expected until an explicit blocker is resolved." --color "D73A4A"
```

The workflow verifies these definitions but never creates or updates labels.
Use **Run workflow** with one item number to retry or explicitly reclassify an
open item. `auto` preserves a valid current state and otherwise uses the draft
fallback above.

After deployment, perform the one-time backfill from an operator shell:

```bash
gh api --paginate "repos/microsoft/BCApps/issues?state=open&per_page=100" --jq '.[].number' |
  while read -r number; do
    gh workflow run TrackWhoseTurn.yaml --repo microsoft/BCApps \
      -f item_number="$number" -f turn=auto
  done
```

## Boundaries

The trusted workflow runs from the default branch, never checks out or executes
pull request code, uses no secrets, and grants only issue-label write and pull
request read access. Per-item runs are serialized; very close conflicting
non-blocked events resolve in workflow processing order. Label changes made with
`GITHUB_TOKEN` do not retrigger workflows, preventing event loops.

The first pull request adding the workflow cannot classify itself before merge.
The backfill does not replay historical conversation. CI failures and fork
workflow approvals do not reliably identify who owns the next action, so this
workflow does not infer turns from them. There is no scheduled reconciliation;
one-item dispatch is the repair path.
