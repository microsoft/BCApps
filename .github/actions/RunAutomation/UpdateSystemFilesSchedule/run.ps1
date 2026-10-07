<#
.Synopsis
    Updates the branch list of the "Update AL-Go System Files" scheduled run so it only targets supported branches.
.Description
    The "Update AL-Go System Files" workflow (UpdateGitHubGoSystemFiles.yaml) is an AL-Go system file and
    picks the branches to run on from the 'workflowSchedule.includeBranches' setting in
    '.github/Update AL-Go System Files.settings.json'. Unlike the other BCApps automations, it does not use
    the GetGitBranches action and therefore has no knowledge of the "Branch is out of support" ruleset.

    This automation rewrites 'workflowSchedule.includeBranches' with the explicit list of every official
    branch (main and releases/*) that is currently in support. The list contains no wildcards and is
    recomputed on every run, so out-of-support branches are dropped and newly created branches are added.
.Parameter runParameters
    A hashtable with the parameters passed by the RunAutomation action (Repository and TargetBranch).
#>
param (
    [Parameter(Mandatory = $true)]
    $runParameters
)

Import-Module $PSScriptRoot\..\..\..\..\build\scripts\EnlistmentHelperFunctions.psm1 -DisableNameChecking

$repository = $runParameters.Repository

$result = @{
    'Files'   = @()
    'Message' = "No update available"
}

$settingsRelativePath = ".github/Update AL-Go System Files.settings.json"
$settingsPath = Join-Path (Get-BaseFolder) $settingsRelativePath

if (-not (Test-Path $settingsPath)) {
    Write-Host "Settings file '$settingsRelativePath' not found. Nothing to update."
    return $result
}

$settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json

if (-not $settings.workflowSchedule) {
    Write-Host "No 'workflowSchedule' configured in '$settingsRelativePath'. Nothing to update."
    return $result
}

$currentBranches = @($settings.workflowSchedule.includeBranches)
Write-Host "Configured branches: $($currentBranches -join ', ')"

# The official branches, matching the definition used by the GetGitBranches action.
$officialBranchPatterns = @('main', 'releases/*')

# Fetch all remote branches so the official branches can be listed explicitly.
RunAndCheck git fetch --quiet origin "+refs/heads/*:refs/remotes/origin/*"
$allBranches = @(RunAndCheck git for-each-ref --format="%(refname:short)" refs/remotes/origin/) | Where-Object { $_ -ne 'origin' } | ForEach-Object { $_ -replace '^origin/', '' }

# Keep only the official branches (main and releases/*) that are in support.
$supportedBranches = @(
    $allBranches | Where-Object {
        $branch = $_
        ($officialBranchPatterns | Where-Object { $branch -like $_ }) -and (Test-IsBranchInSupport -BranchName $branch -Repository $repository)
    }
)

# Order deterministically ('main' first, then release branches in natural numeric order) to keep diffs clean.
function Get-BranchSortKey {
    param([string] $Branch)
    if ($Branch -eq 'main') {
        return '0'
    }
    # Zero-pad numeric segments so e.g. releases/26.2 sorts before releases/26.10.
    $padded = [regex]::Replace($Branch, '\d+', { param($m) $m.Value.PadLeft(10, '0') })
    return "1$padded"
}
$supportedBranches = @($supportedBranches | Select-Object -Unique | Sort-Object { Get-BranchSortKey $_ })

if ($supportedBranches.Count -eq 0) {
    Write-Host "::Warning::No supported official branches found; leaving the schedule unchanged."
    return $result
}

if (($currentBranches -join ',') -eq ($supportedBranches -join ',')) {
    Write-Host "Scheduled branches already match the supported official branches. Nothing to update."
    return $result
}

Write-Host "Updated branches: $($supportedBranches -join ', ')"

$settings.workflowSchedule.includeBranches = @($supportedBranches)
$settings | ConvertTo-Json -Depth 100 | Set-ContentLF -Path $settingsPath

$result.Files = @($settingsRelativePath)
$result.Message = "Update Update AL-Go System Files schedule to only include supported branches"

return $result
