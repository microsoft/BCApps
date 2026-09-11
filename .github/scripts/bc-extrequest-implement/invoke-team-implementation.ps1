[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Finance', 'SCM', 'Integrations')]
    [string] $Team,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Team: Finance', 'Team: SCM', 'Team: Integrations')]
    [string] $TeamLabel,

    [Parameter(Mandatory = $true)]
    [ValidateSet('finance', 'scm', 'integrations')]
    [string] $TeamSlug,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string] $BatchDate,

    [Parameter(Mandatory = $true)]
    [string] $Repository,

    [Parameter(Mandatory = $true)]
    [string] $StatePath,

    [ValidateRange(1, 100)]
    [int] $Limit = 5,

    [string] $Model = 'gpt-5.6-sol',
    [bool] $TelemetryEnabled = $false
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$batchId = "$TeamSlug-$BatchDate"
$branch = "bc-extrequest-implement/team-$batchId"
$runId = "$env:GITHUB_RUN_ID-$env:GITHUB_RUN_ATTEMPT"
$teamLabels = @('Team: Finance', 'Team: SCM', 'Team: Integrations', 'Team: Other')
$requestLabels = @('event-request', 'request-for-external', 'enum-request', 'extensibility-enhancement')
$batchRequestLabels = @('event-request', 'request-for-external')
$workerRoot = Join-Path $env:RUNNER_TEMP "bc-extrequest-$batchId"
$failedIssues = [System.Collections.Generic.List[object]]::new()
$successfulIssues = [System.Collections.Generic.List[object]]::new()
$issueOutcomes = [System.Collections.Generic.List[object]]::new()
$skippedIssueCount = 0

$expectedTeamLabel = "Team: $Team"
if ($TeamLabel -ne $expectedTeamLabel -or $TeamSlug -ne $Team.ToLowerInvariant()) {
    throw "Team, team label, and team slug do not identify the same team."
}

function Invoke-NativeText {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Command,
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments,
        [switch] $AllowFailure
    )

    $output = & $Command @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $text = ($output | Out-String).Trim()
    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw "$Command $($Arguments -join ' ') failed: $text"
    }
    if ($AllowFailure) {
        $global:LASTEXITCODE = 0
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Text = $text
    }
}

function Get-ResultProperty {
    param(
        [Parameter(Mandatory = $true)]
        [object] $Result,
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    $property = $Result.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Send-IssueTelemetry {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('IMPLEMENTATION_STARTED', 'PR_CREATED', 'ERROR')]
        [string] $Tag,
        [Parameter(Mandatory = $true)]
        [long] $IssueNumber,
        [Parameter(Mandatory = $true)]
        [string] $IssueUrl,
        [long] $PullRequestNumber = 0,
        [string] $PullRequestUrl = '',
        [string] $PullRequestState = '',
        [string] $HeadBranch = '',
        [bool] $IsDraft = $false,
        [long] $CommitCount = 0,
        [string] $FailureMessage = ''
    )

    if (-not $TelemetryEnabled) {
        return
    }

    & "$PSScriptRoot/send-telemetry.ps1" `
        -ClusterUri $env:EXT_REQ_KUSTO_CLUSTER_URI `
        -Database $env:EXT_REQ_KUSTO_DATABASE `
        -Table $env:EXT_REQ_KUSTO_IMPLEMENT_TABLE `
        -Tag $Tag `
        -RunId $runId `
        -Repository $Repository `
        -IssueNumber $IssueNumber `
        -IssueUrl $IssueUrl `
        -BatchId $batchId `
        -Model $Model `
        -PullRequestNumber $PullRequestNumber `
        -PullRequestUrl $PullRequestUrl `
        -PullRequestState $PullRequestState `
        -HeadBranch $HeadBranch `
        -IsDraft $IsDraft `
        -CommitCount $CommitCount `
        -FailureMessage $FailureMessage
}

function Get-IssueType {
    param([Parameter(Mandatory = $true)][long] $IssueNumber)

    $parts = @($Repository -split '/', 2)
    if ($parts.Count -ne 2) {
        throw "Repository '$Repository' is not in owner/name format."
    }
    $owner = $parts | Select-Object -First 1
    $repositoryName = $parts | Select-Object -Last 1
    $query = 'query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){issueType{name}}}}'
    $response = Invoke-NativeText -Command 'gh' -Arguments @(
        'api', 'graphql',
        '-f', "query=$query",
        '-f', "owner=$owner",
        '-f', "repo=$repositoryName",
        '-F', "number=$IssueNumber"
    )
    $issueType = (ConvertFrom-Json $response.Text).data.repository.issue.issueType
    if ($null -eq $issueType) {
        return $null
    }
    return $issueType.name
}

function Test-HasOpenPullRequest {
    param([Parameter(Mandatory = $true)][object] $Issue)

    foreach ($reference in @($Issue.closedByPullRequestsReferences)) {
        $referenceRepository = "$($reference.repository.owner.login)/$($reference.repository.name)"
        $response = Invoke-NativeText -Command 'gh' -Arguments @(
            'pr', 'view', "$($reference.number)",
            '--repo', $referenceRepository,
            '--json', 'state'
        ) -AllowFailure
        if ($response.ExitCode -ne 0) {
            Write-Warning "Unable to verify pull request #$($reference.number); skipping issue #$($Issue.number) to avoid duplicate implementation."
            return $true
        }
        if ($response.ExitCode -eq 0 -and (ConvertFrom-Json $response.Text).state -eq 'OPEN') {
            return $true
        }
    }

    return $false
}

function Test-IssueEligible {
    param([Parameter(Mandatory = $true)][object] $Issue)

    if ($Issue.state -ne 'OPEN') {
        return $false
    }

    $labels = @($Issue.labels | ForEach-Object { $_.name })
    if ($labels -notcontains 'ext-ready-to-implement' -or $labels -notcontains $TeamLabel) {
        return $false
    }

    $assignedTeamLabels = @($labels | Where-Object { $_ -in $teamLabels })
    if ($assignedTeamLabels.Count -ne 1) {
        Write-Warning "Skipping issue #$($Issue.number): expected exactly one supported team label."
        return $false
    }

    $assignedRequestLabels = @($labels | Where-Object { $_ -in $requestLabels })
    $assignedRequestLabel = $assignedRequestLabels | Select-Object -First 1
    if ($assignedRequestLabels.Count -ne 1 -or $assignedRequestLabel -notin $batchRequestLabels) {
        return $false
    }

    if ((Get-IssueType -IssueNumber $Issue.number) -ne 'Task') {
        return $false
    }

    return -not (Test-HasOpenPullRequest -Issue $Issue)
}

function Get-EligibleIssues {
    $response = Invoke-NativeText -Command 'gh' -Arguments @(
        'issue', 'list',
        '--repo', $Repository,
        '--state', 'open',
        '--label', 'ext-ready-to-implement',
        '--label', $TeamLabel,
        '--limit', '1000',
        '--json', 'number,title,url,state,updatedAt,labels,closedByPullRequestsReferences'
    )

    $issues = @($response.Text | ConvertFrom-Json)
    return @(
        $issues |
            Sort-Object updatedAt, number |
            Where-Object { Test-IssueEligible -Issue $_ } |
            Select-Object -First $Limit
    )
}

function Get-CurrentIssue {
    param([Parameter(Mandatory = $true)][long] $IssueNumber)

    $response = Invoke-NativeText -Command 'gh' -Arguments @(
        'issue', 'view', "$IssueNumber",
        '--repo', $Repository,
        '--json', 'number,title,url,state,labels,closedByPullRequestsReferences'
    )
    return ConvertFrom-Json $response.Text
}

function Add-JobSummary {
    param([Parameter(Mandatory = $true)][string] $Text)

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $Text
    }
}

function Add-IssueOutcome {
    param(
        [Parameter(Mandatory = $true)][long] $IssueNumber,
        [Parameter(Mandatory = $true)][string] $IssueUrl,
        [Parameter(Mandatory = $true)][string] $IssueTitle,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Implemented', 'No code change', 'Skipped', 'Failed')]
        [string] $Status,
        [Parameter(Mandatory = $true)][string] $Detail
    )

    $issueOutcomes.Add([pscustomobject]@{
        issue_number = $IssueNumber
        issue_url = $IssueUrl
        issue_title = $IssueTitle
        status = $Status
        detail = $Detail
    })
}

function Add-IssueOutcomeSummary {
    $summary = [System.Text.StringBuilder]::new()
    [void]$summary.AppendLine("## $Team")
    [void]$summary.AppendLine()
    [void]$summary.AppendLine('### Issue outcomes')
    [void]$summary.AppendLine()

    foreach ($outcome in $issueOutcomes) {
        $title = ([regex]::Replace([string]$outcome.issue_title, '\s+', ' ')).Trim()
        $detail = ([regex]::Replace([string]$outcome.detail, '\s+', ' ')).Trim()
        [void]$summary.AppendLine(
            "- [#$($outcome.issue_number)]($($outcome.issue_url)) - $title - **$($outcome.status)**: $detail"
        )
    }

    Add-JobSummary $summary.ToString().Trim()
}

function Remove-Worker {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string] $WorkerBranch
    )

    if (Test-Path $Path) {
        Invoke-NativeText -Command 'git' -Arguments @('worktree', 'remove', '--force', $Path) -AllowFailure | Out-Null
    }
    Invoke-NativeText -Command 'git' -Arguments @('branch', '-D', $WorkerBranch) -AllowFailure | Out-Null
}

git config user.name 'github-actions[bot]'
git config user.email '41898282+github-actions[bot]@users.noreply.github.com'

$issues = @(Get-EligibleIssues)
if ($issues.Count -eq 0) {
    Write-Host "No eligible extensibility requests found for $TeamLabel."
    Add-JobSummary "## $Team`n`nNo eligible extensibility requests were found."
    $global:LASTEXITCODE = 0
    return
}

$defaultBranchResponse = Invoke-NativeText -Command 'gh' -Arguments @(
    'repo', 'view', $Repository, '--json', 'defaultBranchRef', '--jq', '.defaultBranchRef.name'
)
$defaultBranch = $defaultBranchResponse.Text
Invoke-NativeText -Command 'git' -Arguments @('fetch', 'origin', $defaultBranch) | Out-Null

$remoteBranch = Invoke-NativeText -Command 'git' -Arguments @(
    'ls-remote', '--heads', 'origin', $branch
) -AllowFailure
$openPrResponse = Invoke-NativeText -Command 'gh' -Arguments @(
    'pr', 'list',
    '--repo', $Repository,
    '--head', $branch,
    '--state', 'open',
    '--limit', '1',
    '--json', 'number'
)
$openPr = @(
    $openPrResponse.Text | ConvertFrom-Json
) | Select-Object -First 1
$replaceRemoteBranch = $false
if ([string]::IsNullOrWhiteSpace($remoteBranch.Text)) {
    Invoke-NativeText -Command 'git' -Arguments @('switch', '-C', $branch, "origin/$defaultBranch") | Out-Null
} elseif ($openPr) {
    Invoke-NativeText -Command 'git' -Arguments @('fetch', 'origin', $branch) | Out-Null
    Invoke-NativeText -Command 'git' -Arguments @('switch', '-C', $branch, "origin/$branch") | Out-Null
} else {
    Write-Warning "Resetting unpublished batch branch '$branch' to origin/$defaultBranch before retrying."
    Invoke-NativeText -Command 'git' -Arguments @('fetch', 'origin', $branch) | Out-Null
    Invoke-NativeText -Command 'git' -Arguments @('switch', '-C', $branch, "origin/$defaultBranch") | Out-Null
    $replaceRemoteBranch = $true
}

New-Item -ItemType Directory -Path $workerRoot -Force | Out-Null

foreach ($discoveredIssue in $issues) {
    $issueNumber = [long]$discoveredIssue.number
    $issueUrl = [string]$discoveredIssue.url
    $issueTitle = [string]$discoveredIssue.title
    $workerBranch = "bc-extrequest-worker/$batchId-$issueNumber-$env:GITHUB_RUN_ATTEMPT"
    $worktreePath = Join-Path $workerRoot "issue-$issueNumber"
    $resultPath = Join-Path $workerRoot "issue-$issueNumber-result.json"

    try {
        $issue = Get-CurrentIssue -IssueNumber $issueNumber
        if (-not (Test-IssueEligible -Issue $issue)) {
            Write-Warning "Skipping issue #$issueNumber because it is no longer eligible."
            Add-IssueOutcome `
                -IssueNumber $issueNumber `
                -IssueUrl $issueUrl `
                -IssueTitle $issueTitle `
                -Status 'Skipped' `
                -Detail 'Issue was no longer eligible when processing started.'
            $skippedIssueCount++
            continue
        }

        Send-IssueTelemetry -Tag IMPLEMENTATION_STARTED -IssueNumber $issueNumber -IssueUrl $issueUrl

        $batchHead = (Invoke-NativeText -Command 'git' -Arguments @('rev-parse', 'HEAD')).Text
        Invoke-NativeText -Command 'git' -Arguments @(
            'worktree', 'add', '-b', $workerBranch, $worktreePath, $batchHead
        ) | Out-Null

        $previousMode = $env:EXT_REQ_SKILL_MODE
        $previousResultPath = $env:EXT_REQ_BATCH_RESULT_PATH
        try {
            $env:EXT_REQ_SKILL_MODE = 'batch-worker'
            $env:EXT_REQ_BATCH_RESULT_PATH = $resultPath
            Push-Location $worktreePath
            try {
                $prompt = @(
                    "Use the /bc-extrequest-implement skill to implement GitHub issue #$issueNumber.",
                    "Execution mode is batch-worker. Follow the skill's batch-worker contract exactly.",
                    "Write the required JSON result to EXT_REQ_BATCH_RESULT_PATH with changed set to the JSON boolean true or false.",
                    "Create one issue commit only when changed is true.",
                    "Do not push, create a pull request, or modify the issue."
                ) -join ' '
                $copilotArgs = @(
                    '--allow-all-tools',
                    '--no-custom-instructions',
                    '--no-color',
                    '--log-level', 'info',
                    "--model=$Model",
                    '-p', $prompt
                )
                & copilot @copilotArgs
                if ($LASTEXITCODE -ne 0) {
                    throw "Copilot CLI exited with code $LASTEXITCODE."
                }
            } finally {
                Pop-Location
            }
        } finally {
            $env:EXT_REQ_SKILL_MODE = $previousMode
            $env:EXT_REQ_BATCH_RESULT_PATH = $previousResultPath
        }

        if (-not (Test-Path $resultPath)) {
            throw 'Copilot completed without writing the batch-worker result.'
        }

        $currentIssue = Get-CurrentIssue -IssueNumber $issueNumber
        if (-not (Test-IssueEligible -Issue $currentIssue)) {
            throw "Issue #$issueNumber is no longer eligible after implementation."
        }

        $result = Get-Content -Raw $resultPath | ConvertFrom-Json
        $resultChanged = Get-ResultProperty -Result $result -Name 'changed'
        if ($resultChanged -isnot [bool]) {
            throw "The batch-worker result must contain 'changed' as a JSON boolean."
        }
        $resultIssueNumber = Get-ResultProperty -Result $result -Name 'issue_number'
        if ($null -eq $resultIssueNumber -or [long]$resultIssueNumber -ne $issueNumber) {
            throw 'The batch-worker result does not match the implemented issue.'
        }
        $resultCommitSha = [string](Get-ResultProperty -Result $result -Name 'commit_sha')
        $resultSummary = [string](Get-ResultProperty -Result $result -Name 'summary')
        $resultChangesMade = @(Get-ResultProperty -Result $result -Name 'changes_made')

        $workerHead = (Invoke-NativeText -Command 'git' -Arguments @('-C', $worktreePath, 'rev-parse', 'HEAD')).Text
        $commitCount = [int](Invoke-NativeText -Command 'git' -Arguments @(
            '-C', $worktreePath, 'rev-list', '--count', "$batchHead..$workerHead"
        )).Text
        $worktreeStatus = (Invoke-NativeText -Command 'git' -Arguments @(
            '-C', $worktreePath, 'status', '--porcelain'
        )).Text
        if (-not [string]::IsNullOrWhiteSpace($worktreeStatus)) {
            throw 'The batch worker left uncommitted changes in its worktree.'
        }

        if ($commitCount -eq 0) {
            if ([string]::IsNullOrWhiteSpace($resultSummary)) {
                throw 'A batch-worker result without an issue commit must contain a summary.'
            }
            if ($resultChangesMade.Count -ne 0) {
                throw 'A batch-worker result without an issue commit must contain no changes.'
            }
            if ($resultChanged) {
                Write-Warning "Issue #$issueNumber reported changed=true but created no commit; treating it as unchanged."
            }

            $skippedIssueCount++
            Add-IssueOutcome `
                -IssueNumber $issueNumber `
                -IssueUrl $issueUrl `
                -IssueTitle $issueTitle `
                -Status 'No code change' `
                -Detail $resultSummary
            Write-Host "Skipped issue #$issueNumber (changed=false): $resultSummary"
            continue
        }

        if ($commitCount -ne 1) {
            throw "Expected exactly one issue commit, but found $commitCount."
        }
        if (-not $resultChanged) {
            Write-Warning "Issue #$issueNumber reported changed=false but created one commit; using the Git history."
        }
        if ([string]::IsNullOrWhiteSpace($resultSummary) -or $resultChangesMade.Count -eq 0) {
            throw 'The implemented batch-worker result does not contain a summary and changes.'
        }
        if (-not [string]::IsNullOrWhiteSpace($resultCommitSha) -and $resultCommitSha -ne $workerHead) {
            Write-Warning "Issue #$issueNumber reported a stale commit SHA; using the worker HEAD."
        }
        $trustedLabels = @(
            $currentIssue.labels |
                ForEach-Object { $_.name } |
                Where-Object { $_ -ne 'ext-ready-to-implement' }
        )
        $result | Add-Member -NotePropertyName issue_title -NotePropertyValue $currentIssue.title -Force
        $result | Add-Member -NotePropertyName issue_url -NotePropertyValue $currentIssue.url -Force
        $result | Add-Member -NotePropertyName labels -NotePropertyValue $trustedLabels -Force
        $result | Add-Member -NotePropertyName changed -NotePropertyValue $true -Force

        $changedFiles = @(
            (Invoke-NativeText -Command 'git' -Arguments @(
                '-C', $worktreePath, 'diff-tree', '--no-commit-id', '--name-only', '-r', $workerHead
            )).Text -split "`n" |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )
        $invalidFiles = @($changedFiles | Where-Object { [IO.Path]::GetExtension($_) -ne '.al' })
        if ($invalidFiles.Count -gt 0) {
            throw "The issue commit contains non-AL files: $($invalidFiles -join ', ')."
        }

        Invoke-NativeText -Command 'git' -Arguments @('cherry-pick', $workerHead) | Out-Null
        $result | Add-Member -NotePropertyName commit_sha `
            -NotePropertyValue (Invoke-NativeText -Command 'git' -Arguments @('rev-parse', 'HEAD')).Text `
            -Force
        $successfulIssues.Add($result)
        Add-IssueOutcome `
            -IssueNumber $issueNumber `
            -IssueUrl $issueUrl `
            -IssueTitle $issueTitle `
            -Status 'Implemented' `
            -Detail $resultSummary
        Write-Host "Implemented issue #$issueNumber."
    } catch {
        $message = $_.Exception.Message
        $cherryPickState = Invoke-NativeText -Command 'git' -Arguments @(
            'rev-parse', '--verify', '--quiet', 'CHERRY_PICK_HEAD'
        ) -AllowFailure
        if ($cherryPickState.ExitCode -eq 0) {
            Invoke-NativeText -Command 'git' -Arguments @('cherry-pick', '--abort') -AllowFailure | Out-Null
        }
        $failedIssues.Add([pscustomobject]@{
            issue_number = $issueNumber
            issue_url = $issueUrl
            failure = $message
        })
        Add-IssueOutcome `
            -IssueNumber $issueNumber `
            -IssueUrl $issueUrl `
            -IssueTitle $issueTitle `
            -Status 'Failed' `
            -Detail $message
        Send-IssueTelemetry `
            -Tag ERROR `
            -IssueNumber $issueNumber `
            -IssueUrl $issueUrl `
            -FailureMessage $message
        Write-Warning "Issue #$issueNumber failed: $message"
    } finally {
        Remove-Worker -Path $worktreePath -WorkerBranch $workerBranch
        Remove-Item -Path $resultPath -Force -ErrorAction SilentlyContinue
    }
}

Add-IssueOutcomeSummary

if ($successfulIssues.Count -eq 0) {
    if ($failedIssues.Count -eq 0 -and $skippedIssueCount -gt 0) {
        $global:LASTEXITCODE = 0
        return
    }
    throw "No issue implementation completed successfully for $TeamLabel."
}

$state = @{
    version = 1
    batch_id = $batchId
    batch_date = $BatchDate
    branch = $branch
    default_branch = $defaultBranch
    repository = $Repository
    team = $Team
    team_label = $TeamLabel
    model = $Model
    replace_remote_branch = $replaceRemoteBranch
    successful_issues = @($successfulIssues)
    failed_issues = @($failedIssues)
}
$state | ConvertTo-Json -Depth 10 | Set-Content -Path $StatePath -Encoding UTF8

Write-Host "Prepared $($successfulIssues.Count) issue implementation(s) for $TeamLabel."
$global:LASTEXITCODE = 0
