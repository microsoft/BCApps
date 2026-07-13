[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $Repository,
    [Parameter(Mandatory)]
    [int] $SubjectNumber,
    [Parameter(Mandatory)]
    [ValidateSet('classify', 'audit', 'audit-if-overridden')]
    [string] $Mode,
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

function Set-DispatchOutput {
    param([Parameter(Mandatory)][bool] $Value)

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_OUTPUT)) {
        Add-Content -Encoding UTF8 -Path $env:GITHUB_OUTPUT -Value "dispatch=$($Value.ToString().ToLowerInvariant())"
    }
}

$labels = @(Get-GitHubSubjectLabelNames -Repository $Repository -SubjectNumber $SubjectNumber)
$state = Get-OwnershipLabelState -LabelNames $labels

if ($state.HasManualOverride) {
    Set-DispatchOutput -Value $false
    if ($state.TeamCount -eq 1) {
        Write-JobSummary "### Ownership override`nManual ownership is valid: **$($state.SelectedTeam)**. Automated classification was skipped."
        return
    }

    if (-not $DryRun) {
        $config = Get-TeamOwnershipConfiguration
        Set-GitHubOwnershipLabels -Repository $Repository -Definitions $config.LabelDefinitions
        if (-not $state.NeedsReview) {
            Add-GitHubSubjectLabel -Repository $Repository -SubjectNumber $SubjectNumber `
                -Label $config.ReviewLabel
        }
    }
    Write-JobSummary "### Ownership override invalid`nExpected exactly one team label while ``Ownership: Manual`` is present; found **$($state.TeamCount)**. Team labels were not changed."
    throw 'Manual ownership override must contain exactly one team label.'
}

if ($Mode -in @('audit', 'audit-if-overridden')) {
    Set-DispatchOutput -Value $false
    Write-JobSummary '### Ownership event ignored`nNo manual ownership override is currently present, so this label event requires no classification.'
    return
}

Set-DispatchOutput -Value $true
Write-JobSummary '### Ownership classification`nThe subject is eligible for automated ownership classification.'
