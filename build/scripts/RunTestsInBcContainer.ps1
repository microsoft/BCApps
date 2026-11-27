Param(
    [Hashtable] $parameters,
    [validateSet("UnitTest","IntegrationTest", "Uncategorized", "Legacy")]
    [string] $TestType,
    # Names of test apps to dispatch in parallel across tenants. Only set by the per-project
    # override on the parent invocation. Empty when called from inside a background job, which
    # forces the sequential single-app path further down.
    [string[]] $AppNamesToTest = @(),
    [switch] $SkipAutomaticDisabledPass,
    # Internal correlation fields passed by Start-TestJob, not forwarded to BcContainerHelper.
    [Hashtable] $Timing
)

$wrapperImportClock = [System.Diagnostics.Stopwatch]::StartNew()
Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1
$enlistmentImported = $?
Import-Module $PSScriptRoot\ParallelTestExecution.psm1
$parallelTestsImported = $?
Import-Module $PSScriptRoot\TestTolerance\TestTolerance.psm1 -Force
$toleranceImported = $?
if ($Timing) {
    $wrapperImportOutcome = if ($enlistmentImported -and $parallelTestsImported -and $toleranceImported) { 'completed' } else { 'error' }
    Write-TestWorkerTiming -Timing $Timing -Event worker-wrapper-imports -Clock $wrapperImportClock -Outcome $wrapperImportOutcome
}

<#
.SYNOPSIS
    Runs Run-TestsInBcContainer and detects silent test truncation caused by BCH ERROR DIALOG events.
.DESCRIPTION
    BCH's ClientContext.ps1 writes "ERROR DIALOG: ..." from inside a Register-ObjectEvent
    handler when the BC client hits an unrecoverable error (e.g. "database command was
    cancelled"). Subscriber actions run in a separate runspace, so the output never flows
    through the caller's pipeline - only to the host console. The test runner silently
    stops calling remaining codeunits and BCH still returns $true, hiding the truncation.

    Start-Transcript hooks at the host level and captures everything written to the console,
    including event-handler output, which lets us re-surface the cancellation as a hard failure.
.OUTPUTS
    [bool] $true if tests passed AND no cancellation was detected; $false otherwise.
#>
function Invoke-RunTestsWithCancellationDetection {
    param(
        [Hashtable]$parameters,
        [Hashtable]$Timing,
        [int]$Pass
    )

    $bchPassed = $false
    $transcriptStartClock = [System.Diagnostics.Stopwatch]::StartNew()
    $transcriptFile = [System.IO.Path]::GetTempFileName()
    $transcriptStarted = $false
    try {
        try {
            Start-Transcript -Path $transcriptFile -Force | Out-Null
            $transcriptStarted = $true
        } catch {
            Write-Host "WARNING: Could not start transcript ($($_.Exception.Message)); BCH cancellation detection disabled for this attempt."
        }
        $transcriptStartClock.Stop()
        $transcriptStartUtc = [datetime]::UtcNow

        $helperCallClock = [System.Diagnostics.Stopwatch]::StartNew()
        $helperCallOutcome = 'error'
        try {
            $bchPassed = Run-TestsInBcContainer @parameters
            $helperCallClock.Stop()
            $helperCallUtc = [datetime]::UtcNow
            $helperCallOutcome = if ($bchPassed) { 'passed' } else { 'failed' }
        } catch {
            $helperCallClock.Stop()
            $helperCallUtc = [datetime]::UtcNow
            $bchPassed = $false
            Write-Host "Exception occurred while running tests: $($_.Exception.Message) / $($_.Exception.StackTrace)"
        }
    }
    finally {
        $transcriptDiagnosticsClock = [System.Diagnostics.Stopwatch]::StartNew()
        if ($transcriptStarted) {
            try { Stop-Transcript | Out-Null } catch { }
        }
    }

    $bchCancelled = $false
    $transientPlatformRace = $false
    $transcriptRead = $false
    $transcriptAvailable = $transcriptStarted -and (Test-Path $transcriptFile)
    if ($transcriptAvailable) {
        $transcriptContent = Get-Content -Path $transcriptFile -Raw
        $transcriptRead = $?
        if ($transcriptContent -match 'database command was cancelled|ERROR DIALOG') {
            Write-Host "::warning::BCH client cancellation detected for app '$($parameters['appName'])' on tenant '$($parameters['tenant'])'. Tests were silently truncated - subsequent codeunits did not run."
            $bchCancelled = $true
        }
        if (Test-TransientTestFailure -Output $transcriptContent) {
            Write-Host "::warning::TRANSIENT TEST PLATFORM RACE detected for app '$($parameters['appName'])' on tenant '$($parameters['tenant'])'."
            $transientPlatformRace = $true
        }
    }
    Remove-Item $transcriptFile -Force -ErrorAction SilentlyContinue
    if ($Timing) {
        $transcriptDiagnosticsClock.Stop()
        $diagnosticUtc = [datetime]::UtcNow
        # Keep timing fields out of the transcript used to make cancellation and retry decisions.
        $transcriptStartOutcome = if ($transcriptStarted) { 'completed' } else { 'unavailable' }
        $diagnosticOutcome = if ($bchCancelled) { 'cancelled' } elseif ($transientPlatformRace) { 'transient' } elseif ($transcriptRead) { 'completed' } else { 'unavailable' }
        Write-TestWorkerTiming -Timing $Timing -Event transcript-start -Utc $transcriptStartUtc -Clock $transcriptStartClock -Outcome $transcriptStartOutcome -Pass $Pass
        Write-TestWorkerTiming -Timing $Timing -Event helper-call -Utc $helperCallUtc -Clock $helperCallClock -Outcome $helperCallOutcome -Pass $Pass
        Write-TestWorkerTiming -Timing $Timing -Event transcript-diagnostics -Utc $diagnosticUtc -Clock $transcriptDiagnosticsClock -Outcome $diagnosticOutcome -Pass $Pass
    }

    return ($bchPassed -and -not $bchCancelled -and -not $transientPlatformRace)
}

function Invoke-TestsWithReruns {
    param(
        [Hashtable]$parameters,
        [int]$maxAttempts = 2,
        [Hashtable]$Timing,
        [int]$Pass = 1
    )
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        $testsSucceeded = Invoke-RunTestsWithCancellationDetection -parameters $parameters -Timing $Timing -Pass $Pass

        # Check if tests succeeded
        if ($testsSucceeded) {
            Write-Host "All tests passed on attempt $($attempt + 1)."
            return $true
        } else {
            $attempt++
            $parameters["ReRun"] = $true
            if ($attempt -ge $maxAttempts) {
                Write-Host "Tests failed after $maxAttempts attempts."
                return $false
            } else {
                Write-Host "Some tests failed. Retrying... (Attempt $($attempt + 1) of $maxAttempts)"
            }
        }
    }
}

$setupClock = [System.Diagnostics.Stopwatch]::StartNew()
if (($null -ne $TestType) -and ($TestType -ne "Legacy")) {
    Write-Host "Using test type $TestType"
    $parameters["testType"] = $TestType
}

$parameters["disabledTests"] = @(Get-DisabledTestsForApp -AppName $parameters["appName"])
$setupOutcome = if ($?) { 'completed' } else { 'error' }
$parameters["renewClientContextBetweenTests"] = $true
if ($Timing) {
    Write-TestWorkerTiming -Timing $Timing -Event worker-setup -Clock $setupClock -Outcome $setupOutcome
}

# When invoked from the per-project override on the parent process, $AppNamesToTest contains
# the full ordered set of apps the project wants to run. We dispatch them all in parallel,
# wait, merge results, and persist the final outcome so subsequent override calls can short-
# circuit. When invoked from inside a background job (Start-TestJob), $AppNamesToTest is empty
# and we fall through to the sequential single-app path below.
if ($AppNamesToTest.Count -gt 0) {
    return Invoke-ParallelTestExecution -parameters $parameters -scriptPath $PSCommandPath -testType $TestType -appNamesToTest $AppNamesToTest
}

$isRequiredDisabledRun = $parameters.ContainsKey("requiredTestIsolation") -and $parameters["requiredTestIsolation"] -eq "Disabled"
# A failing app is retried once by the parallel dispatcher, on a different tenant (see
# ParallelTestExecution.psm1). Retrying in place here would reuse the tenant the app just dirtied,
# so the same residue could re-trigger the failure - hence a single attempt per dispatch.
$result = Invoke-TestsWithReruns -parameters $parameters -maxAttempts 1 -Timing $Timing

# Preserve the old sequential fallback. Parallel project execution defers this pass to the
# clean-tenant codeunit scheduler in ParallelTestExecution.psm1.
if ($TestType -eq "UnitTest" -and -not $SkipAutomaticDisabledPass -and -not $isRequiredDisabledRun) {
    Write-Host "Running DisableTestIsolation pass for UnitTest"
    $parameters["requiredTestIsolation"] = "Disabled"
    $parameters["testRunnerCodeunitId"] = "130451"
    $parameters.Remove("ReRun") # Clear rerun state from the first pass
    $isolationResult = Invoke-TestsWithReruns -parameters $parameters -maxAttempts 1 -Timing $Timing -Pass 2
    $result = $result -and $isolationResult
}

# If tests failed, check if we can tolerate failures based on the test results and unstable tests list.
# Test tolerance only applies to PR builds.
$testResultFileName = if ($parameters.ContainsKey("JUnitResultFileName") -and -not [string]::IsNullOrWhiteSpace($parameters["JUnitResultFileName"])) {
    $parameters["JUnitResultFileName"]
} elseif ($parameters.ContainsKey("XUnitResultFileName") -and -not [string]::IsNullOrWhiteSpace($parameters["XUnitResultFileName"])) {
    $parameters["XUnitResultFileName"]
} else {
    $null
}

$isPullRequest = $env:GITHUB_EVENT_NAME -eq 'pull_request'

if (-not $result -and $testResultFileName -and $isPullRequest) {
    Write-Host "Tests failed. Checking test tolerance using results file: $testResultFileName"

    # Download unstable tests artifact only when tests failed and tolerance may apply
    $toleranceBranch = Get-ToleranceBranch
    Write-Host "Tolerance branch: $toleranceBranch"
    $tempDownloadDir = Join-Path ([System.IO.Path]::GetTempPath()) "unstable-tests-$([System.Guid]::NewGuid().ToString('N'))"
    $toleranceStage = 'unstable-tests-download'
    $toleranceClock = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $UnstableTestsPath = Receive-UnstableTestsArtifact -Branch $toleranceBranch -OutputDirectory $tempDownloadDir
        $downloadOutcome = if ($UnstableTestsPath) { 'completed' } else { 'unavailable' }
        if ($Timing) {
            Write-TestWorkerTiming -Timing $Timing -Event $toleranceStage -Clock $toleranceClock -Outcome $downloadOutcome
        }

        $toleranceStage = 'tolerance'
        $toleranceClock.Restart()
        $result = Test-ShouldTolerateFailures -TestResultsPath $testResultFileName -UnstableTestsPath $UnstableTestsPath
        $toleranceOutcome = if ($result) { 'tolerated' } else { 'failed' }
        if ($Timing) {
            Write-TestWorkerTiming -Timing $Timing -Event $toleranceStage -Clock $toleranceClock -Outcome $toleranceOutcome
        }
        $toleranceStage = $null
        Write-Host "Test tolerance result: $result"
    } finally {
        $toleranceClock.Stop()
        $toleranceEndUtc = [datetime]::UtcNow
        if (Test-Path $tempDownloadDir) {
            Remove-Item -Path $tempDownloadDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        if ($Timing -and $toleranceStage) {
            Write-TestWorkerTiming -Timing $Timing -Event $toleranceStage -Utc $toleranceEndUtc -Clock $toleranceClock -Outcome error
            $Timing.workerFinishEmitted = $true
            Write-TestWorkerTiming -Timing $Timing -Event worker-finish -Clock $Timing.workerClock -Outcome error
        }
    }
} elseif ($Timing) {
    Write-TestWorkerTiming -Timing $Timing -Event tolerance -Outcome skipped
}

return $result
