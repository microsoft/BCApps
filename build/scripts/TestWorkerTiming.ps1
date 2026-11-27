<#
    Filter logs for BCAppsTestTiming and parse the JSON after the prefix. Group by dispatchId
    and order by embedded UTC, not the log timestamp: Receive-Job replays worker output later.
    Compare dispatch to worker-start for launch delay, worker-finish to collection-start for
    time before collection, and collected to the next dispatch on the same tenant for reuse delay.
    elapsedMs is a local stopwatch measurement ending at the event, not a timestamp.
    job-launch measures how long the controller spends in Start-Job. The worker-finish
    duration includes the worker stages; do not sum it with them.
    pass 2 is the legacy sequential Disabled-isolation pass inside a UnitTest worker;
    a scheduler retry instead has its own dispatchId and dispatchKind.

    tenant-wait measures the head-of-queue wait for an eligible tenant, including collection
    in the scheduler. It excludes time elsewhere in the pending queue. Warmup starts on a
    preselected tenant; clean-codeunit dispatch uses a separate batch scheduler. Neither
    emits tenant-wait. Clean-codeunit discovery, restores, result merge, cached results and
    direct sequential invocations are outside these markers. An aborted stage or stopped
    process can leave its completion marker absent. helper-call is the whole stock helper
    call, not per-test time; use the result XML for recorded test durations.
#>
$testWorkerTimingPrefix = 'BCAppsTestTiming '
$testWorkerTimingTag = 'BCAppsTestTiming'

function Write-TestWorkerTiming {
    param(
        [hashtable]$Timing,
        [string]$Event,
        [datetime]$Utc = [datetime]::UtcNow,
        [System.Diagnostics.Stopwatch]$Clock,
        [string]$Outcome,
        [int]$Pass,
        [string]$JobState
    )

    $elapsedMs = if ($Clock) { $Clock.ElapsedMilliseconds }
    $record = [ordered]@{
        event = $Event
        utc = $Utc.ToString('o', [cultureinfo]::InvariantCulture)
        pid = $PID
        dispatchId = $Timing.dispatchId
        app = $Timing.app
        tenant = $Timing.tenant
        itemType = $Timing.itemType
        dispatchKind = $Timing.dispatchKind
    }
    if ($null -ne $elapsedMs) { $record.elapsedMs = $elapsedMs }
    if ($Outcome) { $record.outcome = $Outcome }
    if ($Pass) { $record.pass = $Pass }
    if ($JobState) { $record.jobState = $JobState }
    $line = "$testWorkerTimingPrefix$($record | ConvertTo-Json -Compress)"
    if ($Timing.workerClock) {
        Write-Information -MessageData $line -Tags $testWorkerTimingTag -InformationAction SilentlyContinue
    } else {
        Write-Host $line
    }
}
