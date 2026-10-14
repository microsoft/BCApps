$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
Set-StrictMode -Version Latest

foreach ($name in 'GITHUB_REPOSITORY', 'GITHUB_OUTPUT') {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
        throw "$name must be set."
    }
}

$now = if ($env:NOW_EPOCH) {
    [DateTimeOffset]::FromUnixTimeSeconds([long] $env:NOW_EPOCH)
}
else {
    [DateTimeOffset]::UtcNow
}
$cutoff5Minutes = $now.AddMinutes(-5)
$cutoff30Days = $now.AddDays(-30)
$requestTypeLabels = @(
    'event-request',
    'request-for-external',
    'enum-request',
    'extensibility-enhancement'
)

$newIssues = [System.Collections.Generic.List[int]]::new()
$updatedIssues = [System.Collections.Generic.List[int]]::new()
$staleIssues = [System.Collections.Generic.List[int]]::new()

$issuesJson = gh api "repos/$($env:GITHUB_REPOSITORY)/issues" `
    --paginate --slurp --method GET `
    -f state=open `
    -f type=Task `
    -f per_page=100
$issuePages = $issuesJson | ConvertFrom-Json
$issues = @($issuePages | ForEach-Object { $_ })

foreach ($issue in $issues) {
    $labelNames = @($issue.labels | ForEach-Object { $_.name })
    $hasMissingInfo = $labelNames -contains 'missing-info'
    $hasRequestType = $null -ne ($labelNames | Where-Object { $_ -in $requestTypeLabels } | Select-Object -First 1)
    $hasAgentNotProcessable = $labelNames -contains 'agent-not-processable'
    if ($hasRequestType -or $hasAgentNotProcessable) {
        continue
    }

    $commentsJson = gh api "repos/$($env:GITHUB_REPOSITORY)/issues/$($issue.number)/comments" `
        --paginate --slurp
    $commentPages = $commentsJson | ConvertFrom-Json
    $comments = @($commentPages | ForEach-Object { $_ })
    $hasNotAccurateFeedback = $null -ne (
        $comments |
            Where-Object {
                -not $_.user.login.EndsWith('[bot]', [StringComparison]::OrdinalIgnoreCase) -and
                $_.body -match '(?i)/not-accurate'
            } |
            Select-Object -First 1
    )
    if ($hasNotAccurateFeedback) {
        continue
    }

    $lastComment = $comments | Select-Object -Last 1
    $lastCommentAuthor = if ($lastComment) { [string] $lastComment.user.login } else { '' }
    $lastCommentUpdatedAt = if ($lastComment) {
        [DateTimeOffset]::Parse($lastComment.updated_at)
    }
    else {
        $null
    }
    $createdAt = [DateTimeOffset]::Parse($issue.created_at)
    $updatedAt = [DateTimeOffset]::Parse($issue.updated_at)
    $lastCommentIsBot = $lastCommentAuthor.EndsWith('[bot]', [StringComparison]::OrdinalIgnoreCase)

    if (-not $hasMissingInfo) {
        if ($createdAt -lt $cutoff5Minutes) {
            $newIssues.Add($issue.number)
        }
    }
    elseif ($updatedAt -lt $cutoff30Days) {
        if ($lastCommentIsBot) {
            $staleIssues.Add($issue.number)
        }
    }
    elseif ($updatedAt -lt $cutoff5Minutes) {
        if (-not $lastComment -or -not $lastCommentIsBot -or $updatedAt -gt $lastCommentUpdatedAt) {
            $updatedIssues.Add($issue.number)
        }
    }
}

foreach ($group in @(
        @{ Name = 'New'; Issues = $newIssues },
        @{ Name = 'Updated'; Issues = $updatedIssues },
        @{ Name = 'Stale'; Issues = $staleIssues }
    )) {
    Write-Host "::group::$($group.Name) issues ($($group.Issues.Count))"
    if ($group.Issues.Count -eq 0) {
        Write-Host '  (none)'
    }
    else {
        $group.Issues | ForEach-Object { Write-Host "  #$_" }
    }
    Write-Host '::endgroup::'
}

$allIssues = @($newIssues) + @($updatedIssues) + @($staleIssues)
$issuesJson = ConvertTo-Json -InputObject $allIssues -Compress
Add-Content -Path $env:GITHUB_OUTPUT -Value "issues=$issuesJson"
