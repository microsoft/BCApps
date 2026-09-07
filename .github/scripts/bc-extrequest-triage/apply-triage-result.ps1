param(
    [int] $IssueNumber = $env:ISSUE_NUMBER,
    [string] $ResultPath = 'result/triage-result.json'
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($env:GITHUB_REPOSITORY)) {
    throw 'GITHUB_REPOSITORY must be set.'
}

$result = Get-Content -Path $ResultPath -Raw | ConvertFrom-Json
if ($result.issue_number -ne $IssueNumber) {
    throw "Result is for issue #$($result.issue_number), expected #$IssueNumber."
}

if ($result.skipped) {
    Write-Host "Issue #$IssueNumber was skipped: $($result.reason)"
    exit 0
}

$issuePath = "repos/$($env:GITHUB_REPOSITORY)/issues/$IssueNumber"
$issue = gh api $issuePath | ConvertFrom-Json
$currentLabels = @($issue.labels | ForEach-Object { $_.name })
$desiredLabels = @(
    if ($null -ne $result.labels_to_set) {
        $result.labels_to_set | Select-Object -Unique
    }
)

$currentLabelKey = ($currentLabels | Sort-Object) -join "`0"
$desiredLabelKey = ($desiredLabels | Sort-Object) -join "`0"
$labelsDiffer = $currentLabels.Count -ne $desiredLabels.Count -or $currentLabelKey -cne $desiredLabelKey
if ($desiredLabels.Count -gt 0 -and $labelsDiffer) {
    @{ labels = $desiredLabels } |
        ConvertTo-Json -Compress |
        gh api --method PUT "$issuePath/labels" --input - |
        Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($result.comment_to_post)) {
    @{ body = $result.comment_to_post } |
        ConvertTo-Json -Compress |
        gh api --method POST "$issuePath/comments" --input - |
        Out-Null
}

if ($result.issue_state -eq 'closed' -and $issue.state -ne 'closed') {
    @{
        state        = 'closed'
        state_reason = 'not_planned'
    } |
        ConvertTo-Json -Compress |
        gh api --method PATCH $issuePath --input - |
        Out-Null
}
