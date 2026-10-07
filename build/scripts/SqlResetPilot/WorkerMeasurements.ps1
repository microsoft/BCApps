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
$postMounts = @(Get-ChildItem $output -Filter 'worker-postmount-*.json' -File |
    ForEach-Object { Get-Content $_.FullName -Raw | ConvertFrom-Json })
$phaseMeasurements = @(
    foreach ($receipt in @($postMounts) + @($warmups)) {
        foreach ($phase in $receipt.phases) {
            [PSCustomObject]@{
                tenant = $receipt.tenant; generation = $receipt.generation; phase = $phase.phase
                passed = $phase.passed; elapsedMilliseconds = $phase.elapsedMilliseconds
            }
        }
    }
)
$phaseTotals = @($phaseMeasurements | Group-Object tenant, phase | ForEach-Object {
    @{ tenant = $_.Group[0].tenant; phase = $_.Group[0].phase; attempts = $_.Count
        failures = @($_.Group | Where-Object { -not $_.passed }).Count
        elapsedMilliseconds = ($_.Group | Measure-Object elapsedMilliseconds -Sum).Sum }
})
@{
    startedUtc = $env:WORKER_CELL_STARTED_UTC; completedUtc = [datetime]::UtcNow.ToString('o')
    totalMilliseconds = $totalMs; setupMilliseconds = $setupMs; executionMilliseconds = $executionMs
    timingComplete = ($gaps.Count -eq 0); gaps = $gaps
    definitions = @{
        total = 'Monotonic pre-checkout through post-cleanup; excludes queue/upload'
        setup = 'Monotonic pre-checkout through inventory, before clean discovery'
        execution = 'UTC discovery through full-cohort outcome; includes template, resets, warmups and tests'
        reset = 'Monotonic per-remount host wall time including serial postmount pacing; pacing also recorded separately, not additive'
        warmup = 'Monotonic app warmup, optional companies probe and pretest wait; individual phases and serial postmount pacing retained separately'
        codeunit = 'Original test-attempts startedUtc/completedUtc; includes worker dispatch and collection'
        case = 'Original cohort JUnit time; optional warmup XML may contain zero cases, not isolated HTTP latency'
    }
    resets = $resets; remountOperations = $warmups; codeunitAttempts = $attempts
    postMountOperations = $postMounts; readinessPhaseTotalsByWorker = $phaseTotals
    readinessPhaseMilliseconds = ($phaseMeasurements | Measure-Object elapsedMilliseconds -Sum).Sum
    readinessFailures = @($phaseMeasurements | Where-Object { -not $_.passed })
    successfulWarmupCount = @($warmups | Where-Object { $_.passed -and $_.executed }).Count
    expectedWarmupCountIfFullCandidate = 22
} | ConvertTo-Json -Depth 14 | Set-Content (Join-Path $output 'worker-performance.json')
