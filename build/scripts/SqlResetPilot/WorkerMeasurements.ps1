$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'WorkerWarmup.psm1')
if (-not (Test-WorkerWarmupExperiment)) { throw 'Invalid worker comparison timing identity.' }
$output = Join-Path $env:GITHUB_WORKSPACE 'sql-reset-pilot-output'
$null = New-Item -ItemType Directory -Path $output -Force
$gaps = @()
$execution = $null
$outcome = $null
foreach ($entry in @(@{ name = 'worker-execution-start.json'; variable = 'execution' }, @{ name = 'outcome.json'; variable = 'outcome' })) {
    $path = Join-Path $output $entry.name
    if (Test-Path $path) { Set-Variable -Name $entry.variable -Value (Get-Content $path -Raw | ConvertFrom-Json) }
    else { $gaps += "Missing $($entry.name)" }
}
$totalMs = $null
$setupMs = $null
$executionMs = $null
if ($env:WORKER_CELL_STARTED_TICKS -match '^\d+$' -and $env:WORKER_CELL_FREQUENCY -match '^[1-9]\d*$') {
    $totalMs = ([Diagnostics.Stopwatch]::GetTimestamp() - [long]$env:WORKER_CELL_STARTED_TICKS) * 1000.0 / [long]$env:WORKER_CELL_FREQUENCY
    if ($execution) { $setupMs = ($execution.startedTicks - [long]$env:WORKER_CELL_STARTED_TICKS) * 1000.0 / [long]$env:WORKER_CELL_FREQUENCY }
} else { $gaps += 'Missing pre-checkout monotonic clock' }
if ($execution -and $outcome) {
    $executionMs = ([datetime]$outcome.completedUtc - [datetime]$execution.startedUtc).TotalMilliseconds
}
$resetPath = Join-Path $output 'worker-reset-timing.jsonl'
$resets = @()
if (Test-Path $resetPath) { $resets = @(Get-Content $resetPath | ForEach-Object { $_ | ConvertFrom-Json }) }
else { $gaps += 'Missing reset timing' }
$warmups = @(Get-ChildItem (Join-Path $output 'worker-warmup') -Filter warmup.json -Recurse -File -ErrorAction SilentlyContinue |
    ForEach-Object { Get-Content $_.FullName -Raw | ConvertFrom-Json })
if (-not $warmups.Count) { $gaps += 'Missing remount operation receipts' }
$attempts = @(Get-ChildItem (Join-Path $output 'test-attempts') -Filter outcome.json -Recurse -File -ErrorAction SilentlyContinue |
    ForEach-Object { Get-Content $_.FullName -Raw | ConvertFrom-Json })
@{
    startedUtc = $env:WORKER_CELL_STARTED_UTC; completedUtc = [datetime]::UtcNow.ToString('o')
    totalMilliseconds = $totalMs; setupMilliseconds = $setupMs; executionMilliseconds = $executionMs
    timingComplete = ($gaps.Count -eq 0); gaps = $gaps
    definitions = @{
        total = 'Monotonic pre-checkout through post-cleanup; excludes queue/upload'
        setup = 'Monotonic pre-checkout through inventory, before clean discovery'
        execution = 'UTC discovery through full-cohort outcome; includes template, resets, warmups and tests'
        reset = 'Monotonic per-remount host wall time; discovery restore separately identified by template=default'
        warmup = 'Monotonic per-remount operation including isolated process/startup/result verification; control only records receipt'
        codeunit = 'Original test-attempts startedUtc/completedUtc; includes worker dispatch and collection'
        case = 'Original cohort JUnit time; warmup case time retained separately, not isolated HTTP latency'
    }
    resets = $resets; remountOperations = $warmups; codeunitAttempts = $attempts
    successfulWarmupCount = @($warmups | Where-Object { $_.passed -and $_.executed }).Count
    expectedWarmupCountIfFullCandidate = 22
} | ConvertTo-Json -Depth 14 | Set-Content (Join-Path $output 'worker-performance.json')
