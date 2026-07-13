[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ResultPath,
    [Parameter(Mandatory)]
    [string] $ExpectedCorrelationToken,
    [Parameter(Mandatory)]
    [ValidateSet('issue', 'pull_request')]
    [string] $ExpectedSubjectKind,
    [Parameter(Mandatory)]
    [int] $ExpectedSubjectNumber,
    [Parameter(Mandatory)]
    [string] $Repository,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

Import-Module (Join-Path $PSScriptRoot 'TeamOwnership.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'TeamOwnershipGitHub.psm1') -Force

function Write-JobSummary {
    param([Parameter(Mandatory)][string] $Text)

    Write-Host $Text
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
        Add-Content -Encoding UTF8 -Path $env:GITHUB_STEP_SUMMARY -Value $Text
    }
}

if (-not (Test-Path -LiteralPath $ResultPath -PathType Leaf)) {
    throw "Ownership result file '$ResultPath' does not exist."
}
$resultFile = Get-Item -LiteralPath $ResultPath
if ($resultFile.Length -gt 1MB) {
    throw "Ownership result file exceeds the 1 MiB limit."
}

try {
    $result = Get-Content -LiteralPath $ResultPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20
} catch {
    throw "Ownership result is not valid JSON: $($_.Exception.Message)"
}

# Contract and identity validation intentionally precede every GitHub API mutation.
$decision = Assert-OwnershipResult -Result $result `
    -ExpectedCorrelationToken $ExpectedCorrelationToken `
    -ExpectedSubjectKind $ExpectedSubjectKind `
    -ExpectedSubjectNumber $ExpectedSubjectNumber `
    -ExpectedRepository $Repository

$safeReason = Get-SafeOwnershipSummaryText -Text $decision.Reason
$summary = @"
### Ownership decision
| Field | Value |
| --- | --- |
| Subject | ``$ExpectedSubjectKind #$ExpectedSubjectNumber`` |
| Team | **$($decision.Team)** |
| Source | ``$($decision.Source)`` |
| Confidence | **$($decision.Confidence)** |
| Reason | $safeReason |
"@

$currentLabels = @(Get-GitHubSubjectLabelNames -Repository $Repository -SubjectNumber $ExpectedSubjectNumber)
$state = Get-OwnershipLabelState -LabelNames $currentLabels
if ($state.HasManualOverride) {
    if ($state.TeamCount -ne 1) {
        if (-not $DryRun) {
            $config = Get-TeamOwnershipConfiguration
            Set-GitHubOwnershipLabels -Repository $Repository -Definitions $config.LabelDefinitions
            if (-not $state.NeedsReview) {
                Add-GitHubSubjectLabel -Repository $Repository -SubjectNumber $ExpectedSubjectNumber `
                    -Label $config.ReviewLabel
            }
        }
        Write-JobSummary "$summary`nResult not applied: manual override is invalid and has $($state.TeamCount) team labels."
        throw 'Manual ownership override must contain exactly one team label.'
    }

    Write-JobSummary "$summary`nResult not applied because ``Ownership: Manual`` preserves **$($state.SelectedTeam)**."
    return
}

$initialPlan = Get-OwnershipMutationPlan -SelectedTeam $decision.Team `
    -Confidence $decision.Confidence -CurrentLabels $currentLabels
if ($DryRun) {
    $adds = if ($initialPlan.Add.Count -gt 0) { $initialPlan.Add -join ', ' } else { 'none' }
    $removes = if ($initialPlan.Remove.Count -gt 0) { $initialPlan.Remove -join ', ' } else { 'none' }
    Write-JobSummary "$summary`n**Dry run:** add [$adds]; remove [$removes]."
    return
}

$config = Get-TeamOwnershipConfiguration
Set-GitHubOwnershipLabels -Repository $Repository -Definitions $config.LabelDefinitions

for ($attempt = 1; $attempt -le 3; $attempt++) {
    $currentLabels = @(Get-GitHubSubjectLabelNames -Repository $Repository -SubjectNumber $ExpectedSubjectNumber)
    $state = Get-OwnershipLabelState -LabelNames $currentLabels
    if ($state.HasManualOverride) {
        Write-JobSummary "$summary`nResult not applied because a manual override appeared before mutation."
        return
    }

    $plan = Get-OwnershipMutationPlan -SelectedTeam $decision.Team `
        -Confidence $decision.Confidence -CurrentLabels $currentLabels

    # The selected team is added before competing team labels are removed, avoiding a no-owner window.
    foreach ($label in $plan.Add) {
        Add-GitHubSubjectLabel -Repository $Repository -SubjectNumber $ExpectedSubjectNumber -Label $label
    }
    foreach ($label in $plan.Remove) {
        Remove-GitHubSubjectLabel -Repository $Repository -SubjectNumber $ExpectedSubjectNumber -Label $label
    }

    $verifiedLabels = @(Get-GitHubSubjectLabelNames -Repository $Repository -SubjectNumber $ExpectedSubjectNumber)
    $verified = Get-OwnershipLabelState -LabelNames $verifiedLabels
    $reviewMatches = $verified.NeedsReview -eq $plan.ShouldReview
    if ($verified.TeamCount -eq 1 -and $verified.SelectedTeam -ceq $decision.Team -and $reviewMatches) {
        Write-JobSummary "$summary`nApplied and verified on attempt $attempt."
        return
    }

    if ($verified.HasManualOverride) {
        Write-JobSummary "$summary`nStopped retrying because a manual override appeared during application."
        throw 'Ownership labels changed concurrently with a manual override.'
    }
    Start-Sleep -Seconds (2 * $attempt)
}

Write-JobSummary "$summary`nThe ownership labels did not converge after three attempts."
throw 'Ownership labels failed final exact-one verification.'
