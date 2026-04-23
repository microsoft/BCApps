---
name: backport-pr
description: "Backport a merged or open GitHub pull request from microsoft/BCApps to one or more `releases/*` branches. Use when the user asks to: backport a PR, port a PR/fix to a release branch, cherry-pick a PR to releases/*, create backport PRs, propagate a change to release branches. Wraps `New-BCAppsBackport` from build/scripts/CrossBranchPorting.psm1, resolves the correct linked ADO work item per target branch (does NOT reuse the original work item by default), and optionally enables auto-merge on the resulting PRs."
---

# Backport a PR to release branches

Automates backporting a PR from `main` to one or more `releases/*` branches in `microsoft/BCApps`. The repo provides [build/scripts/CrossBranchPorting.psm1](../../../build/scripts/CrossBranchPorting.psm1) which does the cherry-pick + push + PR creation; this skill wraps it with the right defaults and the per-branch work-item resolution rule used by the team.

## Required inputs

Ask the user for any missing inputs before proceeding:

1. **Source PR number** (e.g. `7830`).
2. **Target branches** — explicit list, OR a glob/intent the agent must expand (e.g. "all `releases/*`", "27.* and 28.*", "all `*.x`"). Always confirm the resolved list before running.
3. **Auto-merge?** (yes/no, default no). If yes, default to `--squash`.

## Pre-flight checks (run in parallel)

1. `gh auth status` — must be authenticated to github.com for the `microsoft/BCApps` repo.
2. `gh pr view <PR> --repo microsoft/BCApps --json state,mergeCommit,potentialMergeCommit,baseRefName,title,body` — verify a cherry-pickable commit exists. Either `mergeCommit` or `potentialMergeCommit` must be non-null. If both are null, stop and tell the user the PR is not yet mergeable.
3. `git fetch origin` and `git branch -r` — confirm every requested target branch exists as `origin/<branch>`. List all `releases/*` branches when expanding a glob.
4. Make sure the working tree is clean (no uncommitted changes) — the script will otherwise prompt to stash.

Show the resolved target branch list to the user and get confirmation before invoking the script.

## Work item handling (IMPORTANT — do NOT reuse the original work item)

The script supports `-ReuseWorkItem`, but **do not pass it by default**. Each release branch has its own ADO work item that mirrors the original (typically created as a child / "Related" link on the source work item, scoped to the target branch's iteration/area path). The backport PR description must reference the work item that targets that specific branch.

For each target branch:

1. Extract the original ADO work item id from the source PR body (regex `AB#(\d+)`).
2. Resolve the per-branch work item:
   - Preferred: query ADO for child / linked work items of the original work item whose Iteration Path or Area Path matches the target release (e.g. `releases/27.3` → iteration containing `27.3`). Use the Azure DevOps work item tools if available (e.g. `mcp_ado_mcp_*` work-item query tools), or `az boards work-item relation show`.
   - If the user has the linked work item ids handy, ask them for a mapping `branch -> work-item-id`.
   - If exactly one linked work item per branch cannot be resolved automatically, **stop and ask the user** for the correct id rather than guessing or reusing the parent.
3. Use `[**Insert Work Item Number Here**]` as the placeholder only as a last resort, and clearly tell the user which PRs need manual editing.

Because per-branch work items are required, run the script **one branch at a time** when you need to inject different work item numbers. The script's bulk mode is only safe when every target branch should use the same id.

## Execution pattern

The script lives at [build/scripts/CrossBranchPorting.psm1](../../../build/scripts/CrossBranchPorting.psm1). Run from the repo root.

### Option A — per-branch loop (recommended, gives per-branch work item)

```powershell
Import-Module ./build/scripts/CrossBranchPorting.psm1 -Force

$pr = '<PR_NUMBER>'
# Map of target branch -> linked ADO work item id (resolved as described above)
$map = @{
    'releases/27.5' = '<WI_ID_FOR_27_5>'
    'releases/28.x' = '<WI_ID_FOR_28_X>'
}

foreach ($branch in $map.Keys) {
    # New-BCAppsBackport hard-codes the work item handling, so to inject a per-branch id
    # the cleanest path is to run it once per branch and then patch the resulting PR body.
    New-BCAppsBackport -PullRequestNumber $pr -TargetBranches @($branch) -SkipConfirmation
    # The script leaves the PR body with "[**Insert Work Item Number Here**]" — replace it.
    $backportPr = gh pr list --repo microsoft/BCApps --state open --search "[$branch] in:title $pr in:body" --json number,body,url | ConvertFrom-Json | Select-Object -First 1
    if ($backportPr) {
        $newBody = $backportPr.body -replace '\[\*\*Insert Work Item Number Here\*\*\]', $map[$branch]
        gh pr edit $backportPr.number --repo microsoft/BCApps --body $newBody
    }
}
```

### Option B — bulk run with the same work item (only if user explicitly opts in)

```powershell
Import-Module ./build/scripts/CrossBranchPorting.psm1 -Force
New-BCAppsBackport -PullRequestNumber <PR> -TargetBranches @('releases/27.x','releases/28.x') -SkipConfirmation -ReuseWorkItem
```

### Handling transient push failures

`git push` may fail with `Recv failure: Connection was reset`. The cherry-pick branch is already created locally and committed, so:
1. Manually retry: `git push origin backport/<branch>/<PR>/<timestamp>`.
2. Then create the PR:

   ```powershell
   gh pr create --title "[<branch>] <original title>" --body "This pull request backports #<PR> to <branch>`r`n`r`nFixes AB#<wi>" --base <branch> --head <cherry-pick-branch>
3. Re-run the script for the *remaining* branches only (the duplicate-detection in the script prevents re-creating an existing PR for the same title+base, but skipping the already-handled branch is cleaner).

## Auto-merge

If the user asked to auto-merge, run after all PRs are created:

```powershell
$prNumbers = @(<list of created PR numbers>)
foreach ($n in $prNumbers) {
    gh pr merge $n --repo microsoft/BCApps --auto --squash
}
```

`--squash` is the default for this repo. Only switch to `--merge` or `--rebase` if the user asks.

## Final report to the user

Always print a markdown table of `branch | PR url`, plus any branches that failed and the reason. If the source PR is still open, remind the user that further changes to it may require refreshing the backports.

## Pitfalls

- **Reusing the parent work item.** Default behavior of the underlying script with `-ReuseWorkItem`. Don't do this for real backports — see the work item section above.
- **Source PR not yet mergeable.** Both `mergeCommit` and `potentialMergeCommit` are null until GitHub finishes computing the merge. Wait or refresh.
- **Glob expansion surprises.** "All `releases/*`" includes very old branches (24.x, 25.x) that usually shouldn't be patched. Always show the expanded list and confirm.
- **Working directory state.** The script switches branches; uncommitted changes will trigger a stash prompt. Confirm a clean tree first.
- **Auto-merge on a blocked PR.** `--auto` queues the merge until all checks/required reviews pass; it does not bypass them. If branch protection requires reviews, the PR will sit until approved.
