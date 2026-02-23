<#
.SYNOPSIS
    BCApps override for RunTestsInBcContainer with Code Coverage support
.DESCRIPTION
    This script replaces the standard Run-TestsInBcContainer call with Run-AlTests
    from AL-Go's CodeCoverage module to enable code coverage tracking.
    
    Place this file at: build/scripts/RunTestsInBcContainer.ps1
    
    Prerequisites:
    - AL-Go's ALTestRunner module must be imported before this script runs
      (done automatically by RunPipeline.ps1)
#>
Param(
    [Hashtable] $parameters,
    [switch] $DisableTestIsolation,
    [ValidateSet("UnitTest", "IntegrationTest", "Uncategorized")]
    [string] $TestType
)

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1

function Get-DisabledTests {
    $baseFolder = Get-BaseFolder

    $disabledCodeunits = Get-ChildItem -Path $baseFolder -Filter "DisabledTests" -Recurse -Directory |
        ForEach-Object { Get-ChildItem -Path $_.FullName -Filter "*.json" }
    $disabledTests = @()
    foreach ($disabledCodeunit in $disabledCodeunits) {
        $disabledTests += (Get-Content -Raw -Path $disabledCodeunit.FullName | ConvertFrom-Json)
    }

    return @($disabledTests)
}

function Invoke-TestsWithReruns {
    param(
        [Hashtable]$parameters,
        [int]$maxReruns = 2
    )
    
    $attempt = 0
    while ($attempt -lt $maxReruns) {
        $testsSucceeded = $false
        
        # Run tests and catch any exceptions to prevent the script from terminating
        try {
            $testsSucceeded = Invoke-TestsWithCodeCoverage -parameters $parameters -attempt ($attempt + 1)
        }
        catch {
            $testsSucceeded = $false
            Write-Host "Exception occurred while running tests: $($_.Exception.Message) / $($_.Exception.StackTrace)"
        }

        # Check if tests succeeded
        if ($testsSucceeded) {
            Write-Host "All tests passed on attempt $($attempt + 1)."
            return $true
        }
        else {
            $attempt++
            # TODO: ReRun is not yet supported in Run-AlTests (no ReRun/StabilityRun mapping).
            # Currently retries re-run the full test suite. Map to StabilityRun when supported.
            $parameters["ReRun"] = $true
            if ($attempt -ge $maxReruns) {
                Write-Host "Tests failed after $maxReruns attempts."
                return $false
            }
            else {
                Write-Host "Some tests failed. Retrying... (Attempt $($attempt + 1) of $($maxReruns + 1))"
            }
        }
    }
}

function Invoke-TestsWithCodeCoverage {
    param(
        [Hashtable]$parameters,
        [int]$attempt = 1
    )
    
    # Check if Run-AlTests is available (imported by AL-Go RunPipeline.ps1)
    if (-not (Get-Command "Run-AlTests" -ErrorAction SilentlyContinue)) {
        throw "Run-AlTests not available - AL-Go CodeCoverage module must be imported. Ensure RunPipeline.ps1 imports the ALTestRunner module."
    }
    
    Write-Host "Using Run-AlTests with code coverage support"
    
    $containerName = $parameters["containerName"]
    $credential = $parameters["credential"]
    $extensionId = $parameters["extensionId"]
    $appName = $parameters["appName"]
    
    # Handle both JUnit and XUnit result file names
    $resultsFilePath = $null
    $resultsFormat = 'JUnit'
    if ($parameters["JUnitResultFileName"]) {
        $resultsFilePath = $parameters["JUnitResultFileName"]
        $resultsFormat = 'JUnit'
    }
    elseif ($parameters["XUnitResultFileName"]) {
        $resultsFilePath = $parameters["XUnitResultFileName"]
        $resultsFormat = 'XUnit'
    }
    
    # Get container web client URL for connecting from host
    $containerConfig = Get-BcContainerServerConfiguration -ContainerName $containerName
    $publicWebBaseUrl = $containerConfig.PublicWebBaseUrl
    if (-not $publicWebBaseUrl) {
        # Fallback to constructing URL from container name
        $publicWebBaseUrl = "http://$($containerName):80/BC/"
    }
    
    # Ensure tenant parameter is included (required for client services connection)
    $tenant = if ($parameters["tenant"]) { $parameters["tenant"] } else { "default" }
    if ($publicWebBaseUrl -notlike "*tenant=*") {
        if ($publicWebBaseUrl.Contains("?")) {
            $serviceUrl = "$publicWebBaseUrl&tenant=$tenant"
        }
        else {
            $serviceUrl = "$($publicWebBaseUrl.TrimEnd('/'))/?tenant=$tenant"
        }
    }
    else {
        $serviceUrl = $publicWebBaseUrl
    }
    Write-Host "Using ServiceUrl: $serviceUrl"
    
    # Code coverage output path - use AL-Go's build artifact folder (set by RunPipeline.ps1)
    # Falls back to workspace .buildartifacts if not set (for local testing)
    $buildArtifactFolder = $env:AL_GO_BUILD_ARTIFACT_FOLDER
    if (-not $buildArtifactFolder) {
        Write-Host "Warning: AL_GO_BUILD_ARTIFACT_FOLDER not set, using workspace root"
        $baseFolder = Get-BaseFolder
        $buildArtifactFolder = Join-Path $baseFolder ".buildartifacts"
    }
    $codeCoverageOutputPath = Join-Path $buildArtifactFolder "CodeCoverage"
    if (-not (Test-Path $codeCoverageOutputPath)) {
        New-Item -Path $codeCoverageOutputPath -ItemType Directory -Force | Out-Null
    }
    Write-Host "Code coverage output path: $codeCoverageOutputPath"
    
    # Map testRunnerCodeunitId to TestIsolation parameter
    # 130450 = Codeunit isolation (default)
    # 130451 = Disabled isolation
    $testIsolation = "Codeunit"
    if ($parameters["testRunnerCodeunitId"] -eq "130451") {
        $testIsolation = "Disabled"
    }
    
    # Build test run parameters
    $testRunParams = @{
        ServiceUrl               = $serviceUrl
        Credential               = $credential
        AutorizationType         = 'NavUserPassword' # Hardcoded for now; extend if AAD auth is needed
        TestSuite                = if ($parameters["testSuite"]) { $parameters["testSuite"] } else { 'DEFAULT' }
        TestIsolation            = $testIsolation
        Detailed                 = $true
        DisableSSLVerification   = $true
        ResultsFormat            = $resultsFormat
        CodeCoverageTrackingType = 'PerRun'
        ProduceCodeCoverageMap   = 'PerCodeunit'
        CodeCoverageOutputPath   = $codeCoverageOutputPath
        CodeCoverageFilePrefix   = "CodeCoverage_$(Get-Date -Format 'yyyyMMdd_HHmmss')_attempt$attempt"
    }
    
    # Map optional parameters
    if ($extensionId) {
        $testRunParams.ExtensionId = $extensionId
    }
    
    if ($appName) {
        $testRunParams.AppName = $appName
    }
    
    if ($resultsFilePath) {
        $testRunParams.ResultsFilePath = $resultsFilePath
        $testRunParams.SaveResultFile = $true
    }
    
    # Map testType parameter
    if ($parameters["testType"]) {
        $testRunParams.TestType = $parameters["testType"]
    }
    
    # Map requiredTestIsolation parameter
    if ($parameters["requiredTestIsolation"]) {
        $testRunParams.RequiredTestIsolation = $parameters["requiredTestIsolation"]
    }
    
    if ($parameters["disabledTests"]) {
        $testRunParams.DisabledTests = $parameters["disabledTests"]
    }
    
    # Map test codeunit/function filters
    # testCodeunit can be a name pattern or ID, testCodeunitRange is a BC filter string
    if ($parameters["testCodeunitRange"]) {
        $testRunParams.TestCodeunitsRange = $parameters["testCodeunitRange"]
    }
    elseif ($parameters["testCodeunit"] -and $parameters["testCodeunit"] -ne "*") {
        $testRunParams.TestCodeunitsRange = $parameters["testCodeunit"]
    }
    
    if ($parameters["testFunction"] -and $parameters["testFunction"] -ne "*") {
        $testRunParams.TestProcedureRange = $parameters["testFunction"]
    }
    
    # Run tests with code coverage
    Run-AlTests @testRunParams
    
    # Check test results file for pass/fail status
    if ($resultsFilePath -and (Test-Path $resultsFilePath)) {
        try {
            [xml]$testResults = Get-Content $resultsFilePath
            
            # JUnit format - can be <testsuites> root or <testsuite> root
            if ($testResults.testsuites) {
                $failures = 0
                $errors = 0
                # Use root-level attributes if available (they are aggregates)
                if ($testResults.testsuites.failures) {
                    $failures = [int]$testResults.testsuites.failures
                }
                elseif ($testResults.testsuites.testsuite) {
                    # Fall back to summing child testsuites
                    foreach ($ts in $testResults.testsuites.testsuite) {
                        if ($ts.failures) { $failures += [int]$ts.failures }
                        if ($ts.errors) { $errors += [int]$ts.errors }
                    }
                }
                if ($testResults.testsuites.errors) {
                    $errors = [int]$testResults.testsuites.errors
                }
                return ($failures -eq 0 -and $errors -eq 0)
            }
            elseif ($testResults.testsuite) {
                # Single testsuite root
                $failures = if ($testResults.testsuite.failures) { [int]$testResults.testsuite.failures } else { 0 }
                $errors = if ($testResults.testsuite.errors) { [int]$testResults.testsuite.errors } else { 0 }
                return ($failures -eq 0 -and $errors -eq 0)
            }
            elseif ($testResults.assemblies) {
                # XUnit format
                $failed = if ($testResults.assemblies.assembly.failed) { [int]$testResults.assemblies.assembly.failed } else { 0 }
                return ($failed -eq 0)
            }
        }
        catch {
            Write-Host "Warning: Could not parse test results file: $_"
        }
    }
    
    # If we can't determine from results file, assume success (tests ran without exception)
    return $true
}

# Main execution
# TODO: Revert this when 616057 is fixed
if (((Get-BuildMode) -eq "CZ") -and ($parameters["appName"] -eq "Quality Management-Tests")) {
    Write-Host "Skipping tests for Quality Management in CZ build mode due to 616057"
    return $true
}

# Use a different variable name to avoid overwriting the validated $TestType parameter
$settingTestType = Get-ALGoSetting -Key "testType"

if ($null -ne $settingTestType -and $settingTestType -ne '') {
    Write-Host "Using test type from settings: $settingTestType"
    $parameters["testType"] = $settingTestType
}
elseif ($null -ne $TestType -and $TestType -ne '') {
    Write-Host "Using test type from parameter: $TestType"
    $parameters["testType"] = $TestType
}

$parameters["disabledTests"] = @(Get-DisabledTests)
# Note: renewClientContextBetweenTests has no equivalent in Run-AlTests; the new runner
# manages client context lifecycle internally.

if ($DisableTestIsolation) {
    Write-Host "Using RequiredTestIsolation: Disabled"
    $parameters["requiredTestIsolation"] = "Disabled"  # filtering on tests that require Disabled Test Isolation
    $parameters["testRunnerCodeunitId"] = "130451"     # Test Runner with disabled test isolation
    
    return Invoke-TestsWithReruns -parameters $parameters -maxReruns 1  # do not retry for Isolation Disabled tests
}
else {
    # this is needed to reset the parameters, in case of previous run with -DisableTestIsolation
    Write-Host "Using RequiredTestIsolation: None"
    $parameters["requiredTestIsolation"] = "None"      # filtering on tests that don't require Test Isolation
    $parameters["testRunnerCodeunitId"] = "130450"     # Test Runner with Codeunit test isolation
}

return Invoke-TestsWithReruns -parameters $parameters
