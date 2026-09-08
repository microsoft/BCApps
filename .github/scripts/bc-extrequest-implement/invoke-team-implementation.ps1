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
    [int] $Limit = 10,

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

    $parts = $Repository.Split('/', 2)
    $query = 'query($owner:String!,$repo:String!,$number:Int!){repository(owner:$owner,name:$repo){issue(number:$number){issueType{name}}}}'
    $response = Invoke-NativeText -Command 'gh' -Arguments @(
        'api', 'graphql',
        '-f', "query=$query",
        '-f', "owner=$($parts[0])",
        '-f', "repo=$($parts[1])",
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
    if ($assignedRequestLabels.Count -ne 1 -or $assignedRequestLabels[0] -notin $batchRequestLabels) {
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
        '--json', 'number,title,url,state,createdAt,labels,closedByPullRequestsReferences'
    )

    $issues = @($response.Text | ConvertFrom-Json)
    return @(
        $issues |
            Sort-Object createdAt |
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
if ([string]::IsNullOrWhiteSpace($remoteBranch.Text)) {
    Invoke-NativeText -Command 'git' -Arguments @('switch', '-c', $branch, "origin/$defaultBranch") | Out-Null
} else {
    Invoke-NativeText -Command 'git' -Arguments @('fetch', 'origin', $branch) | Out-Null
    Invoke-NativeText -Command 'git' -Arguments @('switch', '-C', $branch, "origin/$branch") | Out-Null
}

New-Item -ItemType Directory -Path $workerRoot -Force | Out-Null

foreach ($discoveredIssue in $issues) {
    $issueNumber = [long]$discoveredIssue.number
    $issueUrl = [string]$discoveredIssue.url
    $workerBranch = "bc-extrequest-worker/$batchId-$issueNumber-$env:GITHUB_RUN_ATTEMPT"
    $worktreePath = Join-Path $workerRoot "issue-$issueNumber"
    $resultPath = Join-Path $workerRoot "issue-$issueNumber-result.json"

    try {
        $issue = Get-CurrentIssue -IssueNumber $issueNumber
        if (-not (Test-IssueEligible -Issue $issue)) {
            Write-Warning "Skipping issue #$issueNumber because it is no longer eligible."
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
                    "Create one issue commit and write the required JSON result to EXT_REQ_BATCH_RESULT_PATH.",
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
        $workerHead = (Invoke-NativeText -Command 'git' -Arguments @('-C', $worktreePath, 'rev-parse', 'HEAD')).Text
        $commitCount = [int](Invoke-NativeText -Command 'git' -Arguments @(
            '-C', $worktreePath, 'rev-list', '--count', "$batchHead..$workerHead"
        )).Text
        if ([long]$result.issue_number -ne $issueNumber -or $result.commit_sha -ne $workerHead) {
            throw 'The batch-worker result does not match the implemented issue or commit.'
        }
        if ($commitCount -ne 1) {
            throw "Expected exactly one issue commit, but found $commitCount."
        }
        if ([string]::IsNullOrWhiteSpace([string]$result.summary) -or @($result.changes_made).Count -eq 0) {
            throw 'The batch-worker result does not contain a summary and changes.'
        }
        $trustedLabels = @(
            $currentIssue.labels |
                ForEach-Object { $_.name } |
                Where-Object { $_ -ne 'ext-ready-to-implement' }
        )
        $result | Add-Member -NotePropertyName issue_title -NotePropertyValue $currentIssue.title -Force
        $result | Add-Member -NotePropertyName issue_url -NotePropertyValue $currentIssue.url -Force
        $result | Add-Member -NotePropertyName labels -NotePropertyValue $trustedLabels -Force

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
        $result.commit_sha = (Invoke-NativeText -Command 'git' -Arguments @('rev-parse', 'HEAD')).Text
        $successfulIssues.Add($result)
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

if ($successfulIssues.Count -eq 0) {
    if ($failedIssues.Count -eq 0 -and $skippedIssueCount -gt 0) {
        Add-JobSummary "## $Team`n`nAll discovered issues became ineligible before implementation."
        $global:LASTEXITCODE = 0
        return
    }
    Add-JobSummary "## $Team`n`nNo issue implementation completed successfully."
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
    successful_issues = @($successfulIssues)
    failed_issues = @($failedIssues)
}
$state | ConvertTo-Json -Depth 10 | Set-Content -Path $StatePath -Encoding UTF8

Write-Host "Prepared $($successfulIssues.Count) issue implementation(s) for $TeamLabel."
$global:LASTEXITCODE = 0
