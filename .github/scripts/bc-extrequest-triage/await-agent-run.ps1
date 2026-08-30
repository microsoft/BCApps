$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
Set-StrictMode -Version Latest

foreach ($name in 'AGENT_REPO', 'AGENT_WORKFLOW', 'RUN_TOKEN') {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
        throw "$name must be set."
    }
}

$runListLimit = if ($env:RUN_LIST_LIMIT) { [int] $env:RUN_LIST_LIMIT } else { 100 }
$pollAttempts = if ($env:POLL_ATTEMPTS) { [int] $env:POLL_ATTEMPTS } else { 30 }
$pollIntervalSeconds = if ($env:POLL_INTERVAL_SECONDS) { [int] $env:POLL_INTERVAL_SECONDS } else { 10 }
$watchIntervalSeconds = if ($env:WATCH_INTERVAL_SECONDS) { [int] $env:WATCH_INTERVAL_SECONDS } else { 10 }

$runId = $null
foreach ($attempt in 1..$pollAttempts) {
    $runs = gh run list --repo $env:AGENT_REPO --workflow $env:AGENT_WORKFLOW `
        --json databaseId,displayTitle --limit $runListLimit | ConvertFrom-Json
    $runId = $runs |
        Where-Object { $_.displayTitle.Contains("[$($env:RUN_TOKEN)]") } |
        Select-Object -First 1 -ExpandProperty databaseId
    if ($runId) {
        break
    }

    Start-Sleep -Seconds $pollIntervalSeconds
}

if (-not $runId) {
    Write-Error "Timed out waiting for $($env:AGENT_WORKFLOW) run [$($env:RUN_TOKEN)] to appear."
}

if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_OUTPUT)) {
    Add-Content -Path $env:GITHUB_OUTPUT -Value "run_id=$runId"
}

gh run watch $runId --repo $env:AGENT_REPO --interval $watchIntervalSeconds
