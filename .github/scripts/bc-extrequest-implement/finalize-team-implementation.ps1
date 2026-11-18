[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $StatePath,

    [bool] $TelemetryEnabled = $false
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0
$telemetryEnabledForRun = $TelemetryEnabled

if (-not (Test-Path $StatePath)) {
    throw "Team implementation state '$StatePath' was not found."
}

$state = Get-Content -Raw $StatePath | ConvertFrom-Json
if ($state.version -ne 1 -or @($state.successful_issues).Count -eq 0) {
    throw 'Team implementation state is invalid or contains no successful issues.'
}

function Invoke-NativeText {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Command,
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments,
        [switch] $AllowFailure
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $Command
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $Arguments) {
        [void]$startInfo.ArgumentList.Add($argument)
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        throw "Unable to start '$Command'."
    }
    $standardOutput = $process.StandardOutput.ReadToEndAsync()
    $standardError = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $exitCode = $process.ExitCode
    $text = $standardOutput.GetAwaiter().GetResult().Trim()
    $errorText = $standardError.GetAwaiter().GetResult().Trim()
    $diagnosticParts = @(
        $text
        $errorText
    ) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.Trim() }
    $diagnosticText = ($diagnosticParts -join [Environment]::NewLine).Trim()
    $process.Dispose()
    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw "$Command $($Arguments -join ' ') failed: $diagnosticText"
    }
    if ($AllowFailure) {
        $global:LASTEXITCODE = 0
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Text = $text
        ErrorText = $errorText
        DiagnosticText = $diagnosticText
    }
}

function Send-IssueTelemetry {
    param(
        [Parameter(Mandatory = $true)]
        [long] $IssueNumber,
        [Parameter(Mandatory = $true)]
        [string] $IssueUrl,
        [Parameter(Mandatory = $true)]
        [object] $PullRequest
    )

    if (-not $telemetryEnabledForRun) {
        return
    }

    & "$PSScriptRoot/send-telemetry.ps1" `
        -ClusterUri $env:EXT_REQ_KUSTO_CLUSTER_URI `
        -Database $env:EXT_REQ_KUSTO_DATABASE `
        -Table $env:EXT_REQ_KUSTO_IMPLEMENT_TABLE `
        -Tag PR_CREATED `
        -RunId "$env:GITHUB_RUN_ID-$env:GITHUB_RUN_ATTEMPT" `
        -Repository $state.repository `
        -IssueNumber $IssueNumber `
        -IssueUrl $IssueUrl `
        -BatchId $state.batch_id `
        -Model $state.model `
        -PullRequestNumber ([long]$PullRequest.number) `
        -PullRequestUrl $PullRequest.html_url `
        -PullRequestState $PullRequest.state `
        -HeadBranch $PullRequest.head.ref `
        -IsDraft ([bool]$PullRequest.draft) `
        -CommitCount ([long]$PullRequest.commits)
    $global:LASTEXITCODE = 0
}

function Add-JobSummary {
    param([Parameter(Mandatory = $true)][string] $Text)

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
        Add-Content -Path $env:GITHUB_STEP_SUMMARY -Value $Text
    }
}

function Get-OpenPullRequest {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Repository,
        [Parameter(Mandatory = $true)]
        [string] $RepositoryOwner,
        [Parameter(Mandatory = $true)]
        [string] $Branch
    )

    $response = Invoke-NativeText -Command 'gh' -Arguments @(
        'api',
        '--method', 'GET',
        "repos/$Repository/pulls",
        '-f', 'state=open',
        '-f', "head=$RepositoryOwner`:$Branch",
        '-F', 'per_page=1'
    )
    return @(
        $response.Text | ConvertFrom-Json
    ) | Select-Object -First 1
}

$phase = 'initialization'
$prBodyPath = $null
$requestPath = $null
try {
    $repositoryParts = @([string]$state.repository -split '/', 2)
    if ($repositoryParts.Count -ne 2) {
        throw "Repository '$($state.repository)' is not in owner/name format."
    }
    $repositoryOwner = $repositoryParts | Select-Object -First 1

    $phase = 'Git authentication'
    Write-Host "Publication phase: $phase"
    Invoke-NativeText -Command 'git' -Arguments @(
        'config', '--local', '--unset-all', 'http.https://github.com/.extraheader'
    ) -AllowFailure | Out-Null
    Invoke-NativeText -Command 'gh' -Arguments @('auth', 'setup-git') | Out-Null

    $phase = 'branch push'
    Write-Host "Publication phase: $phase"
    $pushArguments = @('push', '--set-upstream', 'origin', [string]$state.branch)
    $replaceRemoteBranchProperty = $state.PSObject.Properties['replace_remote_branch']
    if ($null -ne $replaceRemoteBranchProperty -and [bool]$replaceRemoteBranchProperty.Value) {
        $pushArguments = @('push', '--force-with-lease', '--set-upstream', 'origin', [string]$state.branch)
    }
    Invoke-NativeText -Command 'git' -Arguments $pushArguments | Out-Null

    $phase = 'existing pull request lookup'
    Write-Host "Publication phase: $phase"
    $existingPr = Get-OpenPullRequest `
        -Repository $state.repository `
        -RepositoryOwner $repositoryOwner `
        -Branch $state.branch

    $phase = 'pull request body generation'
    Write-Host "Publication phase: $phase"
    $sections = [System.Text.StringBuilder]::new()
    foreach ($result in @($state.successful_issues)) {
        [void]$sections.AppendLine("### Issue #$($result.issue_number) - $($result.issue_title)")
        [void]$sections.AppendLine()
        [void]$sections.AppendLine([string]$result.summary)
        [void]$sections.AppendLine()
        [void]$sections.AppendLine('#### Changes Made')
        foreach ($change in @($result.changes_made)) {
            [void]$sections.AppendLine("- $change")
        }
        [void]$sections.AppendLine()
        [void]$sections.AppendLine("Fixes #$($result.issue_number)")
        [void]$sections.AppendLine()
    }

    $sectionMarker = '<!-- EXT_REQ_BATCH_END -->'
    $newSections = $sections.ToString().Trim()
    if ($existingPr) {
        $existingBody = [string]$existingPr.body
        if (-not $existingBody.Contains($sectionMarker)) {
            throw "Existing pull request #$($existingPr.number) does not contain the batch section marker."
        }
        $prBody = $existingBody.Replace($sectionMarker, "$newSections`n`n$sectionMarker")
    } else {
        $prBody = @"
## Summary

$newSections

$sectionMarker

> [!IMPORTANT]
> AI-generated: content may be inaccurate or incomplete. Please review and verify before relying on or merging.
"@
    }

    $temporaryDirectory = [IO.Path]::GetDirectoryName($StatePath)
    $prBodyPath = Join-Path $temporaryDirectory 'pull-request-body.md'
    Set-Content -Path $prBodyPath -Value $prBody -Encoding UTF8
    $prTitle = "[Extensibility Requests][Team: $($state.team)] $($state.batch_date) batch"

    $phase = 'pull request create or update'
    Write-Host "Publication phase: $phase"
    $requestPath = Join-Path $temporaryDirectory 'pull-request-request.json'
    if ($existingPr) {
        @{
            title = $prTitle
            body = $prBody
        } |
            ConvertTo-Json |
            Set-Content -Path $requestPath -Encoding UTF8
        $pullRequestResponse = Invoke-NativeText -Command 'gh' -Arguments @(
            'api',
            '--method', 'PATCH',
            "repos/$($state.repository)/pulls/$($existingPr.number)",
            '--input', $requestPath
        )
    } else {
        @{
            title = $prTitle
            body = $prBody
            base = [string]$state.default_branch
            head = [string]$state.branch
            draft = $true
        } |
            ConvertTo-Json |
            Set-Content -Path $requestPath -Encoding UTF8
        $pullRequestResponse = Invoke-NativeText -Command 'gh' -Arguments @(
            'api',
            '--method', 'POST',
            "repos/$($state.repository)/pulls",
            '--input', $requestPath
        ) -AllowFailure
        if ($pullRequestResponse.ExitCode -ne 0) {
            $existingPr = Get-OpenPullRequest `
                -Repository $state.repository `
                -RepositoryOwner $repositoryOwner `
                -Branch $state.branch
            if (-not $existingPr) {
                throw "Pull request creation failed: $($pullRequestResponse.DiagnosticText)"
            }

            Write-Warning "Pull request creation raced with another publisher; updating pull request #$($existingPr.number)."
            $existingBody = [string]$existingPr.body
            if (-not $existingBody.Contains($sectionMarker)) {
                throw "Concurrent pull request #$($existingPr.number) does not contain the batch section marker."
            }
            $prBody = $existingBody.Replace($sectionMarker, "$newSections`n`n$sectionMarker")
            @{
                title = $prTitle
                body = $prBody
            } |
                ConvertTo-Json |
                Set-Content -Path $requestPath -Encoding UTF8
            $pullRequestResponse = Invoke-NativeText -Command 'gh' -Arguments @(
                'api',
                '--method', 'PATCH',
                "repos/$($state.repository)/pulls/$($existingPr.number)",
                '--input', $requestPath
            )
        }
    }
    $prDetails = $pullRequestResponse.Text | ConvertFrom-Json
    $pullRequestNumber = [long]$prDetails.number
    if ($pullRequestNumber -le 0 -or [string]::IsNullOrWhiteSpace([string]$prDetails.html_url)) {
        throw 'The pull request API response did not contain a valid number and URL.'
    }

    $phase = 'pull request labels'
    Write-Host "Publication phase: $phase"
    $labels = @(
        $state.successful_issues |
            ForEach-Object { @($_.labels) } |
            Where-Object { $_ -ne 'ext-ready-to-implement' } |
            Sort-Object -Unique
    )
    if ($labels.Count -gt 0) {
        @{ labels = $labels } |
            ConvertTo-Json |
            Set-Content -Path $requestPath -Encoding UTF8
        $addLabels = Invoke-NativeText -Command 'gh' -Arguments @(
            'api',
            '--method', 'POST',
            "repos/$($state.repository)/issues/$pullRequestNumber/labels",
            '--input', $requestPath
        ) -AllowFailure
        if ($addLabels.ExitCode -ne 0) {
            Write-Warning "Unable to add labels to pull request #$pullRequestNumber`: $($addLabels.DiagnosticText)"
        }
    }

    $phase = 'telemetry and summary'
    Write-Host "Publication phase: $phase"
    foreach ($result in @($state.successful_issues)) {
        Send-IssueTelemetry `
            -IssueNumber ([long]$result.issue_number) `
            -IssueUrl ([string]$result.issue_url) `
            -PullRequest $prDetails
    }

    $summary = @(
        "## $($state.team)",
        '',
        "Draft pull request: $($prDetails.html_url)",
        '',
        "Implemented issues: $(@($state.successful_issues | ForEach-Object { "#$($_.issue_number)" }) -join ', ')"
    )
    if (@($state.failed_issues).Count -gt 0) {
        $summary += ''
        $summary += "Failed issues: $(@($state.failed_issues | ForEach-Object { "#$($_.issue_number)" }) -join ', ')"
    }
    Add-JobSummary ($summary -join "`n")

    Write-Host "Draft pull request ready: $($prDetails.html_url)"
    if (@($state.failed_issues).Count -gt 0) {
        $phase = 'partial batch result'
        throw "$(@($state.failed_issues).Count) issue implementation(s) failed after the partial batch pull request was created."
    }
    $global:LASTEXITCODE = 0
} catch {
    $line = $_.InvocationInfo.ScriptLineNumber
    Write-Error `
        "Team batch publication failed during '$phase' at line $line`: $($_.Exception.Message)" `
        -ErrorAction Continue
    if (-not [string]::IsNullOrWhiteSpace($_.ScriptStackTrace)) {
        Write-Error $_.ScriptStackTrace -ErrorAction Continue
    }
    throw
} finally {
    if (-not [string]::IsNullOrWhiteSpace($prBodyPath)) {
        Remove-Item -Path $prBodyPath -Force -ErrorAction SilentlyContinue
    }
    if (-not [string]::IsNullOrWhiteSpace($requestPath)) {
        Remove-Item -Path $requestPath -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -Path $StatePath -Force -ErrorAction SilentlyContinue
}
