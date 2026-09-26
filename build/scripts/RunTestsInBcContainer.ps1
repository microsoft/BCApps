Param(
    [Hashtable] $parameters,
    [validateSet("UnitTest","IntegrationTest", "Uncategorized", "Legacy")]
    [string] $TestType,
    # Names of test apps to dispatch in parallel across tenants. Only set by the per-project
    # override on the parent invocation. Empty when called from inside a background job, which
    # forces the sequential single-app path further down.
    [string[]] $AppNamesToTest = @()
)

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1
Import-Module $PSScriptRoot\TestTolerance\TestTolerance.psm1 -Force

function Get-DisabledTests
{
    param(
        [string] $AppName
    )

    $baseFolder = Get-BaseFolder

    # Convert app name to folder name format (replace spaces with underscores)
    $appFolderName = $AppName -replace ' ', '_'

    $disabledTests = @()

    # Look for DisabledTests folders and find the app-specific subfolder
    $disabledTestsFolders = Get-ChildItem -Path $baseFolder -Filter "DisabledTests" -Recurse -Directory
    foreach ($disabledTestsFolder in $disabledTestsFolders) {
        $appFolder = Join-Path $disabledTestsFolder.FullName $appFolderName
        if (Test-Path $appFolder) {
            $jsonFiles = Get-ChildItem -Path $appFolder -Filter "*.json"
            foreach ($jsonFile in $jsonFiles) {
                $disabledTests += (Get-Content -Raw -Path $jsonFile.FullName | ConvertFrom-Json)
            }
        }
    }

    return @($disabledTests)
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
        [Hashtable]$parameters
    )

    $bchPassed = $false
    $transcriptFile = [System.IO.Path]::GetTempFileName()
    $transcriptStarted = $false
    try {
        try {
            Start-Transcript -Path $transcriptFile -Force | Out-Null
            $transcriptStarted = $true
        } catch {
            Write-Host "WARNING: Could not start transcript ($($_.Exception.Message)); BCH cancellation detection disabled for this attempt."
        }

        try {
            $bchPassed = Run-TestsInBcContainer @parameters
        } catch {
            $bchPassed = $false
            Write-Host "Exception occurred while running tests: $($_.Exception.Message) / $($_.Exception.StackTrace)"
        }
    }
    finally {
        if ($transcriptStarted) {
            try { Stop-Transcript | Out-Null } catch { }
        }
    }

    $bchCancelled = $false
    if ($transcriptStarted -and (Test-Path $transcriptFile)) {
        if (Select-String -Path $transcriptFile -Pattern 'database command was cancelled|ERROR DIALOG' -Quiet) {
            Write-Host "::warning::BCH client cancellation detected for app '$($parameters['appName'])' on tenant '$($parameters['tenant'])'. Tests were silently truncated - subsequent codeunits did not run."
            $bchCancelled = $true
        }
    }
    Remove-Item $transcriptFile -Force -ErrorAction SilentlyContinue

    return ($bchPassed -and -not $bchCancelled)
}

function Invoke-TestsWithReruns {
    param(
        [Hashtable]$parameters,
        [int]$maxAttempts = 2
    )
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        $testsSucceeded = Invoke-RunTestsWithCancellationDetection -parameters $parameters

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

<#
.SYNOPSIS
    Fails the run when a [Test] method declared in an executed test codeunit never produced a result.
.DESCRIPTION
    A test object can fail runtime AL-to-C# code generation (or be truncated mid-run) so that some
    of its [Test] methods are silently dropped while the codeunit still reports success and no
    failed result is written - reruns and test tolerance cannot see this. This reconciles the
    declared [Test] methods (read from the AL source) against those in the run's JUnit results.

    Rule: for every codeunit that produced at least one result, every declared, non-disabled [Test]
    method must appear in the results. A codeunit with zero results is ignored (legitimately
    filtered out by test-type / codeunit-range selection).
.OUTPUTS
    [bool] $true when every declared, non-disabled test in an executed codeunit ran; $false otherwise.
#>
function Test-AllSelectedTestsExecuted {
    param(
        [Hashtable]$parameters
    )

    $resultsPath = if ($parameters.ContainsKey("JUnitResultFileName")) { $parameters["JUnitResultFileName"] } else { $null }
    if ([string]::IsNullOrWhiteSpace($resultsPath) -or -not (Test-Path $resultsPath)) {
        Write-Host "No JUnit result file available; skipping declared-vs-executed reconciliation."
        return $true
    }

    try {
        [xml]$doc = Get-Content -Path $resultsPath -Raw -ErrorAction Stop
    } catch {
        Write-Host "WARNING: Could not read JUnit results '$resultsPath' ($($_.Exception.Message)); skipping reconciliation."
        return $true
    }

    # Executed [Test] methods per codeunit id. GetAttribute (not member access) is StrictMode-safe.
    $executed = @{}
    foreach ($suite in $doc.SelectNodes('//testsuite')) {
        $suiteName = $suite.GetAttribute('name') # suite name is "<id> <name>"
        if ([string]::IsNullOrWhiteSpace($suiteName) -or ($suiteName -notmatch '^\s*(\d+)\s')) { continue }
        $cuId = [int]$Matches[1]
        if (-not $executed.ContainsKey($cuId)) { $executed[$cuId] = [System.Collections.Generic.HashSet[string]]::new() }
        foreach ($tc in $suite.SelectNodes('testcase')) {
            $tcName = $tc.GetAttribute('name')
            if ([string]::IsNullOrWhiteSpace($tcName)) { continue }
            # A tolerated failure is re-labelled "<method> (tolerated)"; strip the annotation to match.
            if ($tcName -match '^(?<m>\S+)\s+\(.+\)\s*$') { $tcName = $Matches['m'] }
            [void]$executed[$cuId].Add($tcName)
        }
    }
    if ($executed.Count -eq 0) {
        Write-Host "No executed test codeunits found in results; skipping reconciliation."
        return $true
    }

    # Disabled methods, keyed "<id>|<method>".
    $disabled = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($d in @($parameters["disabledTests"])) {
        if ($null -eq $d) { continue }
        $props = $d.PSObject.Properties
        if ($props['codeunitId'] -and $props['method'] -and ($null -ne $d.codeunitId) -and ($null -ne $d.method)) {
            [void]$disabled.Add("$([int]$d.codeunitId)|$([string]$d.method)")
        }
    }

    # Declared [Test] methods per codeunit, parsed from AL source under 'test' folders. Only
    # codeunits that ran are reconciled, so pre-filter files to those declaring one of them.
    $declared = @{}
    $baseFolder = Get-BaseFolder
    $executedIdPattern = 'codeunit\s+(?:' + (($executed.Keys | ForEach-Object { [regex]::Escape("$_") }) -join '|') + ')\b'
    $testFolders = @(Get-ChildItem -Path $baseFolder -Recurse -Directory -Filter 'test' -ErrorAction SilentlyContinue)
    $alFiles = foreach ($tf in $testFolders) { Get-ChildItem -Path $tf.FullName -Recurse -Filter '*.al' -File -ErrorAction SilentlyContinue }
    foreach ($alFile in $alFiles) {
        $raw = Get-Content -Path $alFile.FullName -Raw -ErrorAction SilentlyContinue
        if ($null -eq $raw) { continue }
        if ($raw -notmatch $executedIdPattern) { continue }
        # Strip comments so a commented-out [Test] is not counted as declared.
        $raw = [regex]::Replace($raw, '(?s)/\*.*?\*/', "`n")
        $lines = ($raw -split "`r?`n") | ForEach-Object { $_ -replace '//.*$', '' }
        $cuId = $null
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\s*codeunit\s+(\d+)\s') {
                $cuId = [int]$Matches[1]
                if (-not $declared.ContainsKey($cuId)) { $declared[$cuId] = [System.Collections.Generic.HashSet[string]]::new() }
                continue
            }
            if (($null -ne $cuId) -and ($lines[$i] -match '^\s*\[Test\]\s*$')) {
                for ($j = $i + 1; $j -lt [Math]::Min($i + 10, $lines.Count); $j++) {
                    if ($lines[$j] -match '^\s*(local\s+)?procedure\s+(\w+)') {
                        [void]$declared[$cuId].Add($Matches[2]); break
                    }
                }
            }
        }
    }

    # Reconcile: every declared, non-disabled method of an executed codeunit must have run.
    $violations = @()
    foreach ($cuId in $executed.Keys) {
        if (-not $declared.ContainsKey($cuId)) { continue }
        $missing = @($declared[$cuId] | Where-Object {
            (-not $executed[$cuId].Contains($_)) -and (-not $disabled.Contains("$cuId|$_"))
        })
        if ($missing.Count -gt 0) {
            $violations += [pscustomobject]@{
                CodeunitId = $cuId
                Declared   = $declared[$cuId].Count
                Executed   = $executed[$cuId].Count
                Missing    = @($missing | Sort-Object)
            }
        }
    }

    if ($violations.Count -eq 0) {
        Write-Host "Declared-vs-executed reconciliation passed: every declared, non-disabled test in an executed codeunit ran."
        return $true
    }

    $totalMissing = ($violations | ForEach-Object { $_.Missing.Count } | Measure-Object -Sum).Sum
    Write-Host "::error::Silently skipped test methods detected: $totalMissing declared, non-disabled [Test] method(s) never ran even though their codeunit executed. This is a hard defect (e.g. a runtime AL-to-C# code-generation failure the platform swallows), not flaky instability."
    foreach ($v in $violations) {
        Write-Host "::error::  Codeunit $($v.CodeunitId): declared $($v.Declared), executed $($v.Executed), missing $($v.Missing.Count): $([string]::Join(', ', $v.Missing))"
    }
    return $false
}

if (($null -ne $TestType) -and ($TestType -ne "Legacy")) {
    Write-Host "Using test type $TestType"
    $parameters["testType"] = $TestType
}

$parameters["disabledTests"] = @(Get-DisabledTests -AppName $parameters["appName"]) # Add disabled tests to parameters
$parameters["renewClientContextBetweenTests"] = $true

# When invoked from the per-project override on the parent process, $AppNamesToTest contains
# the full ordered set of apps the project wants to run. We dispatch them all in parallel,
# wait, merge results, and persist the final outcome so subsequent override calls can short-
# circuit. When invoked from inside a background job (Start-TestJob), $AppNamesToTest is empty
# and we fall through to the sequential single-app path below.
if ($AppNamesToTest.Count -gt 0) {
    Import-Module $PSScriptRoot\ParallelTestExecution.psm1
    return Invoke-ParallelTestExecution -parameters $parameters -scriptPath $PSCommandPath -testType $TestType -appNamesToTest $AppNamesToTest
}

# A failing app is retried once by the parallel dispatcher, on a different tenant (see
# ParallelTestExecution.psm1). Retrying in place here would reuse the tenant the app just dirtied,
# so the same residue could re-trigger the failure - hence a single attempt per dispatch.
$result = Invoke-TestsWithReruns -parameters $parameters -maxAttempts 1

# For UnitTests, also run with DisableTestIsolation on the same tenant
if ($TestType -eq "UnitTest") {
    Write-Host "Running DisableTestIsolation pass for UnitTest"
    $parameters["requiredTestIsolation"] = "Disabled"
    $parameters["testRunnerCodeunitId"] = "130451"
    $parameters.Remove("ReRun") # Clear rerun state from the first pass
    $isolationResult = Invoke-TestsWithReruns -parameters $parameters -maxAttempts 1
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
    try {
        $UnstableTestsPath = Receive-UnstableTestsArtifact -Branch $toleranceBranch -OutputDirectory $tempDownloadDir
        $result = Test-ShouldTolerateFailures -TestResultsPath $testResultFileName -UnstableTestsPath $UnstableTestsPath
        Write-Host "Test tolerance result: $result"
    } finally {
        if (Test-Path $tempDownloadDir) {
            Remove-Item -Path $tempDownloadDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Catch [Test] methods silently dropped at runtime (which reruns and tolerance cannot see) by
# reconciling declared vs executed tests. Checked last, even when $result was tolerated.
if (-not (Test-AllSelectedTestsExecuted -parameters $parameters)) {
    return $false
}

return $result
