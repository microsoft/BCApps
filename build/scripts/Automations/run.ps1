<#
.Synopsis
    Run automations and open a PR with the updates.
    The script is to be run in a GitHub Actions workflow.
.Description
    This script runs all the automations in the folder and opens a PR with the updates.
    The automations are currently run consecutively and the PR is opened if there are updates available.
    The PR is opened with a commit for each update (from an automation).
    The script fails if any automation fails.
.Parameter Include
    The list of automation names to include. If not provided, all automations in the folder are included.
.Parameter Repository
    The repository to open the PR in.
.Parameter TargetBranch
    The target branch for the PR.
.Parameter Actor
    The actor to use for the commits.
#>
param(
    [Parameter(Mandatory=$true)]
    [string[]] $Include,
    [Parameter(Mandatory=$true)]
    [string] $Repository,
    [Parameter(Mandatory=$true)]
    [string] $TargetBranch,
    [Parameter(Mandatory=$true)]
    [string] $Actor
)

$ErrorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0

function RunAutomation {
    param(
        [Parameter(Mandatory=$true)]
        [string] $AutomationName,
        [Parameter(Mandatory=$true)]
        [string] $Repository,
        [Parameter(Mandatory=$true)]
        [string] $TargetBranch
    )

    $automationPath = Join-Path $PSScriptRoot $AutomationName
    try {
        $automationResult = $null
        $automationStatus = "No update available"

        # Run the automation
        # The automation is a script that returns an object with the following properties:
        # - Files: The files changed by the automation
        # - Message: The message to be used for the commit
        $runParameters = @{
            'Repository' = $Repository
            'TargetBranch' = $TargetBranch
        }
        $automationResult = . (Join-Path $automationPath 'run.ps1') -runParameters $runParameters

        if ($automationResult -and ($automationResult.Keys -ccontains 'Files') -and ($automationResult.Keys -ccontains 'Message')) {
            $automationStatus = "Update available"
        }
    } catch {
        $automationStatus = "Failed"
        Write-Host "::Error::Error running automation: $($_.Exception.Message)"
    }
    finally {
        $automationRun = @{
            'Name' = $automationName
            'Result' = $automationResult
            'Status' = $automationStatus
        }
    }

    Write-Host "Automation run: $automationRun"
    return $automationRun
}

function OpenPR {
    param(
        [Parameter(Mandatory=$true)]
        [array] $AvailableUpdates,
        [Parameter(Mandatory=$true)]
        [string] $Repository,
        [Parameter(Mandatory=$true)]
        [string] $TargetBranch,
        [Parameter(Mandatory=$true)]
        [string] $Actor
    )

    Write-Host "Opening PR for the following updates:"
    $AvailableUpdates | ForEach-Object {
        Write-Host "- $($_.Name): $($_.Result | Format-Table | Out-String)"
    }

    Set-GitConfig -Actor $Actor
    $branch = New-TopicBranch -Category "updates/$TargetBranch"

    # Open PR with a commit for each update
    $AvailableUpdates | ForEach-Object {
        $automationResult = $_.Result

        $commitMessage = "$($automationResult.Message)"
        $commitFiles = $automationResult.Files

        git add $commitFiles | Out-Null
        git commit -m $commitMessage | Out-Null
    }

    git push -u origin $branch | Out-Null

    return New-GitHubPullRequest -Repository $Repository -BranchName $branch -TargetBranch $TargetBranch
}

$automationsFolder = $PSScriptRoot
# An automation is a folder with a run.ps1 file
$automationNames = Get-ChildItem -Path $automationsFolder -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'run.ps1') } | ForEach-Object { $_.Name }

# Filter out the automations that are not included
if($Include) {
    $automationNames = $automationNames | Where-Object { $Include -contains $_ }
}

if(-not $automationNames) {
    throw "No automations match the include filter: $($Include -join ', ')" # Fail if no automations are found
}

$automationRuns = @()

foreach ($automationName in $automationNames) {
    Write-Host "::group::Run automation: $automationName"

    $automationRun = RunAutomation -AutomationName $automationName -Repository $Repository -TargetBranch $TargetBranch
    Write-Host "::Notice::Automation $($automationRun.Name) completed. Status: $($automationRun.Status). Message: $($automationRun.Result.Message)"

    $automationRuns += $automationRun
    Write-Host "::endgroup::"
}

$availableUpdates = $automationRuns | Where-Object { $_.Status -eq "Update available" }
if($availableUpdates) { # Only open PR if there are updates
    Write-Host "::group::Create PR for available updates"
    Import-Module $PSScriptRoot\AutomatedSubmission.psm1 -DisableNameChecking

    $prLink = OpenPR -AvailableUpdates $availableUpdates -Repository $Repository -TargetBranch $TargetBranch -Actor $Actor

    Write-Host "::Notice::PR created: $prLink"
    Write-Host "::endgroup::"
}

# Fail if any automation failed
$failedAutomations = $automationRuns | Where-Object { $_.Status -eq "Failed" } | ForEach-Object { $_.Name }
if ($failedAutomations) {
    throw "The following automations failed: $($failedAutomations -join ', '). See logs above."
}