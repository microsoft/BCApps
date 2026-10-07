param([ValidateSet('Start', 'Finish')][string]$Phase)
$ErrorActionPreference = 'Stop'
$directory = Join-Path $env:GITHUB_WORKSPACE 'sql-reset-pilot-output'
$null = New-Item -ItemType Directory -Path $directory -Force
if ($Phase -eq 'Start') {
    @{
        utc = $env:BC_SQL_CELL_STARTED_UTC; ticks = [long]$env:BC_SQL_CELL_STARTED_TICKS
        frequency = [Diagnostics.Stopwatch]::Frequency
    } | ConvertTo-Json | Set-Content (Join-Path $directory 'cell-clock.json')
    Import-Module (Join-Path $PSScriptRoot 'TenantResources.psm1') -Force
    Get-SqlTenantResourceSample -Phase 'setup-start' | ConvertTo-Json -Depth 8 |
        Set-Content (Join-Path $directory 'setup-resource-sample.json')
    return
}
$measurement = @{
    finishedUtc = [DateTime]::UtcNow.ToString('o'); measurementErrors = @()
    totalMilliseconds = $null; setupMilliseconds = $null; executionMilliseconds = $null
    resetMilliseconds = $null; cases = @(); apiTargetCases = @()
    note = 'Monotonic total includes checkout through cleanup, excludes queue time and artifact upload. GitHub job timestamps provide authoritative full job duration. XML time is AL test-case duration, not isolated HTTP latency.'
}
try {
    $clock = Get-Content (Join-Path $directory 'cell-clock.json') -Raw | ConvertFrom-Json
    $measurement.totalMilliseconds = ([Diagnostics.Stopwatch]::GetTimestamp() - $clock.ticks) * 1000.0 / $clock.frequency
    $phases = @(Get-Content (Join-Path $directory 'phase-timing.jsonl') | ForEach-Object { $_ | ConvertFrom-Json })
    $execution = @($phases | Where-Object phase -eq 'execution-including-discovery-template-resets')
    if ($execution.Count -ne 1) { throw 'Exactly one measured execution phase required.' }
    $measurement.executionMilliseconds = $execution[0].elapsedMilliseconds
    $measurement.setupMilliseconds = ($execution[0].startedTicks - $clock.ticks) * 1000.0 / $clock.frequency
    $measurement.executionCompleted = $execution[0].completed
} catch { $measurement.measurementErrors += "phase-timing:$($_.Exception.GetType().FullName)" }
try {
    $resets = @(Get-Content (Join-Path $directory 'reset-timeline.jsonl') | ForEach-Object { $_ | ConvertFrom-Json } |
        Where-Object phase -eq 'reset-complete')
    $measurement.completedResets = $resets.Count
    $measurement.resetMilliseconds = ($resets.observation | Measure-Object elapsedMilliseconds -Sum).Sum
} catch { $measurement.measurementErrors += "reset-timing:$($_.Exception.GetType().FullName)" }
try {
    [xml]$xml = Get-Content (Join-Path $directory 'final-junit.xml') -Raw
    $measurement.cases = @($xml.SelectNodes('/testsuites/testsuite/testcase') | ForEach-Object {
        @{ suite = $_.ParentNode.GetAttribute('name'); name = $_.GetAttribute('name')
            seconds = $_.GetAttribute('time'); skipped = [bool]$_.SelectSingleNode('skipped')
            failed = [bool]$_.SelectSingleNode('failure | error') }
    })
    $measurement.apiTargetCases = @($measurement.cases | Where-Object name -eq 'CapabilitiesProjectsEnabledViaAPI')
    if ($measurement.cases.Count -ne 253 -or $measurement.apiTargetCases.Count -ne 1) { throw 'Incomplete case timings.' }
} catch { $measurement.measurementErrors += "case-timing:$($_.Exception.GetType().FullName)" }
if (-not (Test-Path (Join-Path $directory 'resource-status.json'))) {
    $measurement.measurementErrors += 'resource-status:missing'
} else {
    $measurement.resourceStatus = Get-Content (Join-Path $directory 'resource-status.json') -Raw | ConvertFrom-Json
    if (-not $measurement.resourceStatus.measurementComplete) { $measurement.measurementErrors += 'resource-status:incomplete' }
}
$measurement.measurementComplete = $measurement.measurementErrors.Count -eq 0
$measurement | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $directory 'performance.json')
