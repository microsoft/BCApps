Param(
    [Hashtable] $parameters,
    [validateSet("UnitTest","IntegrationTest", "Uncategorized", "Legacy")]
    [string] $TestType,
    # Names of test apps to dispatch in parallel across tenants. Only set by the per-project
    # override on the parent invocation. Empty when called from inside a background job, which
    # forces the sequential single-app path further down.
    [string[]] $AppNamesToTest = @()
)

Import-Module $PSScriptRoot/../../Shared/EnlistmentHelperFunctions.psm1
Import-Module $PSScriptRoot/../../CI/TestTolerance/TestTolerance.psm1 -Force

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
    Import-Module $PSScriptRoot/../../CI/ParallelTestExecution.psm1
    return Invoke-ParallelTestExecution -parameters $parameters -scriptPath $PSCommandPath -testType $TestType -appNamesToTest $AppNamesToTest
}

$maxAttempts = if ($TestType -eq "Legacy") { 1 } else { 2 }
$result = Invoke-TestsWithReruns -parameters $parameters -maxAttempts $maxAttempts

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

return $result
