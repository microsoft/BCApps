# ------------------------------------------------------------------------------
# Vendored from spetersenms/AL-Go @ spetersen/separateTestAction (commit b733a94).
# Source: Actions/RunTests/AlToolTestRunner.psm1
#
# AL-Go RunTests action's batched altool runner. Invoke-AlToolTestRun runs an app's
# test codeunits in a single `al runtests --testgroups` call (one shared server
# session per app) and filters by the native `-TestType` parameter (UnitTest /
# IntegrationTest / Uncategorized), which maps to the platform Test Tool page's
# TestType control via Get-TestsFromBcContainer.
#
# BCApps' RunTestsInBcContainer.ps1 override drives this module for the
# IntegrationTest and Uncategorized buckets while keeping BCApps' parallel-tenant
# fan-out, reruns and test tolerance. To refresh, re-copy the file from the AL-Go
# branch above and keep this header. DisabledTests must be passed as hashtable[].
#
# NOTE: batching reuses one session across a codeunit group, so until altool's
# per-codeunit session renewal ships, expect cross-codeunit state leakage failures
# (e.g. "codeunit ... already been bound" and mock-provider poisoning) that a
# per-codeunit runner would not exhibit.
# ------------------------------------------------------------------------------
<#
.SYNOPSIS
    Executes tests with AlTool and produces JUnit XML compatible with AL-Go AnalyzeTests.

.DESCRIPTION
    This is the default RunTests executor when no RunTestsInBcContainer override is supplied.
    BcContainerHelper provides app metadata, container configuration, company discovery, and test
    enumeration. AlTool runs each app's enabled methods as one batch and writes the outcomes as JUnit.
#>

$ErrorActionPreference = "Stop"

$script:AlToolPackageId = "Microsoft.Dynamics.BusinessCentral.Development.Tools"

<#
.SYNOPSIS
    Invokes a native executable and returns its output streams and exit code.
.DESCRIPTION
    Keeps stdout separate from native stderr and restores the caller's error preference immediately
    after invocation. Windows PowerShell 5 stderr can include PowerShell formatting metadata.
    Command resolution and invocation failures remain terminating.
.PARAMETER FilePath
    The native executable name or path.
.PARAMETER ArgumentList
    Arguments passed to the native executable.
.OUTPUTS
    [pscustomobject] with StandardOutput, StandardError, combined Output, and ExitCode properties.
#>
function Invoke-AlNativeCommand {
    param(
        [Parameter(Mandatory = $true)][string] $FilePath,
        [string[]] $ArgumentList = @()
    )

    $nativeCommand = Get-Command -Name $FilePath -CommandType Application -ErrorAction Stop
    $standardErrorPath = Join-Path ([System.IO.Path]::GetTempPath()) "altool-stderr-$([Guid]::NewGuid().ToString('N')).txt"
    $originalErrorActionPreference = $ErrorActionPreference
    $nativeErrorPreference = Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue
    $originalNativeErrorPreference = if ($nativeErrorPreference) { $nativeErrorPreference.Value } else { $null }
    try {
        try {
            $ErrorActionPreference = "Continue"
            if ($nativeErrorPreference) {
                $PSNativeCommandUseErrorActionPreference = $false
            }
            $standardOutput = & $nativeCommand.Source @ArgumentList 2> $standardErrorPath
            [int] $exitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $originalErrorActionPreference
            if ($nativeErrorPreference) {
                $PSNativeCommandUseErrorActionPreference = $originalNativeErrorPreference
            }
        }

        [string[]] $standardOutputLines = @($standardOutput | ForEach-Object { "$_" })
        if (Test-Path -LiteralPath $standardErrorPath) {
            [string[]] $standardErrorLines = @(Get-Content -LiteralPath $standardErrorPath | ForEach-Object { "$_" })
        }
        else {
            [string[]] $standardErrorLines = @()
        }

        return [PSCustomObject]@{
            StandardOutput = $standardOutputLines
            StandardError  = $standardErrorLines
            Output         = [string[]] (@($standardOutputLines) + @($standardErrorLines))
            ExitCode       = $exitCode
        }
    }
    finally {
        Remove-Item -LiteralPath $standardErrorPath -Force -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Ensures the `al` CLI is available on PATH, installing the prerelease dotnet global tool.
.DESCRIPTION
    Installs the AL developer tools when unavailable. A named mutex prevents concurrent jobs from
    modifying the shared tool store at the same time.
.OUTPUTS
    [string] The resolved `al` version string.
#>
function Install-AlTool {
    param()

    $userProfile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
    if ([string]::IsNullOrWhiteSpace($userProfile)) {
        throw "Could not resolve the current user's profile directory required for the dotnet global tools path."
    }
    $toolsPath = Join-Path (Join-Path $userProfile ".dotnet") "tools"
    if (($env:PATH -split [System.IO.Path]::PathSeparator) -notcontains $toolsPath) {
        $env:PATH = "$env:PATH$([System.IO.Path]::PathSeparator)$toolsPath"
    }

    # Serialize install/update across processes with a named mutex and re-check availability after
    # acquiring it (another job may have just installed it).
    $mutex = New-Object System.Threading.Mutex($false, "Global\AL-Go-AlTool-Install")
    $acquired = $false
    try {
        try { $acquired = $mutex.WaitOne([TimeSpan]::FromMinutes(10)) } catch [System.Threading.AbandonedMutexException] { $acquired = $true }
        if (-not $acquired) {
            throw "Timed out after 10 minutes waiting to acquire the AlTool installation mutex."
        }

        $alAvailable = $null -ne (Get-Command al -ErrorAction SilentlyContinue)

        if (-not $alAvailable) {
            Write-Host "Installing '$script:AlToolPackageId' (prerelease) as a dotnet global tool..."
            $installResult = Invoke-AlNativeCommand -FilePath "dotnet" -ArgumentList @(
                "tool", "install", $script:AlToolPackageId, "--global", "--prerelease"
            )
            $installResult.Output | ForEach-Object { Write-Host $_ }
            if ($installResult.ExitCode -ne 0) {
                # A concurrent job may have installed it first; treat as success if `al` now resolves,
                # otherwise fall back to an update.
                if ($null -eq (Get-Command al -ErrorAction SilentlyContinue)) {
                    $updateResult = Invoke-AlNativeCommand -FilePath "dotnet" -ArgumentList @(
                        "tool", "update", $script:AlToolPackageId, "--global", "--prerelease"
                    )
                    $updateResult.Output | ForEach-Object { Write-Host $_ }
                    if ($updateResult.ExitCode -ne 0) {
                        throw "Failed to install or update '$script:AlToolPackageId'. The fallback dotnet tool update exited with code $($updateResult.ExitCode). Output: $($updateResult.Output -join [Environment]::NewLine)"
                    }
                }
            }
        }
    }
    finally {
        if ($acquired) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }

    if (-not (Get-Command al -ErrorAction SilentlyContinue)) {
        throw "The 'al' CLI is not available after installation. Ensure '$toolsPath' is on PATH and that the runner can reach nuget.org."
    }

    $versionResult = Invoke-AlNativeCommand -FilePath "al" -ArgumentList @("--version")
    if ($versionResult.ExitCode -ne 0) {
        throw "Failed to run 'al --version'. The command exited with code $($versionResult.ExitCode). Output: $($versionResult.Output -join [Environment]::NewLine)"
    }
    if ($versionResult.StandardOutput.Count -eq 0) {
        throw "Failed to run 'al --version'. The command returned no output."
    }
    $version = $versionResult.StandardOutput[0]
    Write-Host "Using al CLI version: $version"
    return "$version"
}

<#
.SYNOPSIS
    Resolves the on-prem connection settings (server URL, instance, dev-service port) for a container.
.DESCRIPTION
    Reads the container server configuration required by AlTool and falls back to conventional
    defaults when it is unavailable.
.PARAMETER ContainerName
    The name of the build container.
.OUTPUTS
    [hashtable] @{ Server; ServerInstance; Port }
#>
function Get-AlToolConnection {
    param(
        [Parameter(Mandatory = $true)][string] $ContainerName
    )

    $server = "http://$ContainerName"
    $instance = "BC"
    $port = 7049

    try {
        $config = Get-BcContainerServerConfiguration -ContainerName $ContainerName
        if ($config) {
            if ($config.ServerInstance) { $instance = "$($config.ServerInstance)" }
            if ($config.DeveloperServicesPort) { $port = [int]$config.DeveloperServicesPort }
        }
    }
    catch {
        Write-Host "WARNING: Could not read server configuration for '$ContainerName' ($($_.Exception.Message)). Falling back to $server/${instance}:$port."
    }

    return @{ Server = $server; ServerInstance = $instance; Port = $port }
}

<#
.SYNOPSIS
    Resolves the company `al runtests` should target.
.DESCRIPTION
    Uses an explicitly requested company or selects a container company, preferring an evaluation
    company.
.PARAMETER ContainerName
    The name of the build container.
.PARAMETER Tenant
    The tenant to connect to.
.PARAMETER CompanyName
    The company name requested by the caller (optional).
.OUTPUTS
    [string] Company name, or empty string if none could be resolved.
#>
function Get-AlToolCompany {
    param(
        [Parameter(Mandatory = $true)][string] $ContainerName,
        [Parameter(Mandatory = $true)][string] $Tenant,
        [string] $CompanyName = ""
    )

    if (-not [string]::IsNullOrWhiteSpace($CompanyName)) {
        return $CompanyName
    }

    try {
        $companies = @(Get-CompanyInBcContainer -containerName $ContainerName -tenant $Tenant)
        if ($companies.Count -gt 0) {
            $preferred = $companies | Where-Object { $_.evaluationCompany -eq $true } | Select-Object -First 1
            $company = if ($preferred) { $preferred.companyName } else { $companies[0].companyName }
            return "$company"
        }
    }
    catch {
        Write-Host "WARNING: Could not enumerate companies for '$ContainerName' ($($_.Exception.Message))."
    }
    return ""
}

<#
.SYNOPSIS
    Builds case-insensitive disabled-method and disabled-codeunit lookups.
.DESCRIPTION
    A `*` method disables the complete codeunit instead of a method named `*`.
.PARAMETER DisabledTests
    Array of disabled-test hashtables.
.OUTPUTS
    [hashtable] @{ Methods = <set of "<codeunitname>::<method>">; Codeunits = <set of "<codeunitname>"> }
#>
function Get-DisabledTestKeySet {
    param(
        [AllowEmptyCollection()][hashtable[]] $DisabledTests = @()
    )

    $methodSet = @{}
    $codeunitSet = @{}
    foreach ($entry in $DisabledTests) {
        if (-not $entry) { continue }
        $cuName = "$($entry['codeunitName'])".ToLowerInvariant()
        $methods = @()
        if ($entry.ContainsKey('method') -and $entry['method']) { $methods = @($entry['method']) }
        foreach ($m in $methods) {
            if ("$m" -eq '*') {
                $codeunitSet[$cuName] = $true
            }
            else {
                $methodSet["$cuName::$("$m".ToLowerInvariant())"] = $true
            }
        }
    }
    return @{ Methods = $methodSet; Codeunits = $codeunitSet }
}

<#
.SYNOPSIS
    Enumerates enabled test methods for an app in the container.
.DESCRIPTION
    Removes configured disabled methods and codeunits before AlTool execution.
.PARAMETER ContainerName
    Container whose tests are enumerated.
.PARAMETER Credential
    Credential used to access the container.
.PARAMETER ExtensionId
    App ID whose test codeunits are enumerated.
.PARAMETER Tenant
    Tenant used for test enumeration.
.PARAMETER TestType
    Optional platform test type. Supported values are UnitTest, IntegrationTest, and Uncategorized.
    Blank enumerates all test types.
.PARAMETER DisabledTests
    Hashtable entries describing test methods or codeunits excluded from the run.
.OUTPUTS
    [object[]] Codeunit objects with .Id, .Name, .Tests (enabled method name array).
#>
function Get-AlToolTestCodeunits {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $ContainerName,
        [Parameter(Mandatory = $true)][System.Management.Automation.PSCredential] $Credential,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $ExtensionId,
        [string] $Tenant = "default",
        [string] $TestType = "",
        [AllowEmptyCollection()][hashtable[]] $DisabledTests = @()
    )

    $getTestsParams = @{
        containerName = $ContainerName
        tenant        = $Tenant
        credential    = $Credential
        extensionId   = $ExtensionId
        ignoreGroups  = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($TestType)) {
        $supportedTestTypes = @("UnitTest", "IntegrationTest", "Uncategorized")
        $matchingTestType = @($supportedTestTypes | Where-Object { $_ -eq $TestType })
        if ($matchingTestType.Count -eq 0) {
            throw "Unsupported testType '$TestType' for the built-in AlTool runner. Supported values are UnitTest, IntegrationTest, Uncategorized, or blank."
        }
        $getTestsParams["testType"] = $matchingTestType[0]
    }

    $codeunits = @(Get-TestsFromBcContainer @getTestsParams)

    $disabledMethods = @{}
    $disabledCodeunits = @{}
    if ($DisabledTests.Count -gt 0) {
        $lookup = Get-DisabledTestKeySet -DisabledTests $DisabledTests
        $disabledMethods = $lookup.Methods
        $disabledCodeunits = $lookup.Codeunits
    }

    $result = @()
    $disabledCount = 0
    foreach ($cu in $codeunits) {
        $cuNameLower = "$($cu.Name)".ToLowerInvariant()
        $methods = @($cu.Tests | ForEach-Object { "$_" })

        if ($disabledCodeunits.ContainsKey($cuNameLower)) {
            $disabledCount += $methods.Count
            continue
        }

        if ($disabledMethods.Count -gt 0) {
            $enabled = @($methods | Where-Object { -not $disabledMethods.ContainsKey("$cuNameLower::$("$_".ToLowerInvariant())") })
            $disabledCount += ($methods.Count - $enabled.Count)
            $methods = $enabled
        }
        if ($methods.Count -gt 0) {
            $result += [PSCustomObject]@{ Id = $cu.Id; Name = $cu.Name; Tests = $methods }
        }
    }

    if ($disabledCount -gt 0) {
        Write-Host "Excluded $disabledCount disabled test method(s) from altool enumeration."
    }
    return @($result)
}

function ConvertFrom-AlFailureOutput {
    param(
        [AllowEmptyString()][string] $Output
    )

    $messageLines = @()
    $stackLines = @()
    $inStack = $false
    foreach ($line in @("$Output" -split "\r?\n")) {
        if ($line -match '^\s*AL Callstack:\s*$') {
            $inStack = $true
            continue
        }
        if ($line.Trim().Length -eq 0) { continue }
        if ($inStack) {
            $stackLines += $line.Trim()
        }
        else {
            $messageLines += $line.Trim()
        }
    }

    return @{
        Message    = ($messageLines -join ' ').Trim()
        Stacktrace = ($stackLines -join ';')
    }
}

<#
.SYNOPSIS
    Parses an AlTool test-groups ToolResponse into result occurrences.
.DESCRIPTION
    Parses every structurally valid result occurrence from the default ToolResponse JSON contract.
    A CLI or input failure before ToolResponse serialization has empty OutputLines; its diagnostics
    are emitted on stderr by the native command.
.PARAMETER OutputLines
    The complete structured stdout from `al runtests --testgroups`.
.OUTPUTS
    [hashtable] containing the parsed envelope state, result occurrences, and message.
.EXAMPLE
    $outputLines = @'
    {
      "succeeded": true,
      "message": "Test run completed.",
      "data": {
        "success": true,
        "results": [
          { "codeunitId": 130001, "methodName": "TestOne[Case A]", "status": "passed", "output": "", "durationMs": 12 }
        ]
      },
      "nextSteps": [],
      "warnings": []
    }
    '@
    ConvertFrom-AlTestGroupsOutput -OutputLines $outputLines
.EXAMPLE
    $outputLines = @'
    {
      "succeeded": false,
      "message": "One or more tests failed.",
      "data": {
        "success": false,
        "results": [
          { "codeunitId": 130001, "methodName": "TestOne", "status": "failed", "output": "Assertion failed.\nAL Callstack:\nTestOne line 10", "durationMs": 25 }
        ]
      },
      "nextSteps": [],
      "errorDetails": {
        "code": "TestRunFailed",
        "description": "One or more tests failed.",
        "possibleCauses": [],
        "suggestedActions": ["Review the failed test output."],
        "alternatives": [],
        "missingPrerequisites": [],
        "diagnosticHints": ["Inspect the AL callstack."],
        "retryable": false
      },
      "warnings": []
    }
    '@
    ConvertFrom-AlTestGroupsOutput -OutputLines $outputLines
.EXAMPLE
    $outputLines = @'
    {
      "succeeded": false,
      "message": "The server connection is not configured.",
      "nextSteps": ["Configure the Business Central server connection."],
      "errorDetails": {
        "code": "ConnectionConfigurationMissing",
        "description": "No server connection configuration was found.",
        "possibleCauses": ["The project configuration is incomplete."],
        "suggestedActions": ["Add the missing server settings."],
        "alternatives": [],
        "missingPrerequisites": ["Business Central server connection"],
        "diagnosticHints": ["Verify the project launch configuration."],
        "retryable": false
      },
      "warnings": ["No test run was started."]
    }
    '@
    ConvertFrom-AlTestGroupsOutput -OutputLines $outputLines
#>
function ConvertFrom-AlTestGroupsOutput {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][AllowEmptyString()][string[]] $OutputLines
    )

    $json = ($OutputLines -join [Environment]::NewLine).Trim()
    try {
        $toolResponse = ConvertTo-HashTable -object ($json | ConvertFrom-Json) -recurse
    }
    catch {
        throw "The structured stdout could not be parsed as JSON: $($_.Exception.Message)"
    }

    if (-not $toolResponse.ContainsKey("succeeded") -or $toolResponse.succeeded -isnot [bool]) {
        throw "The structured response does not contain a valid Boolean ToolResponse succeeded value."
    }

    $responseMessage = ""
    if ($toolResponse.ContainsKey("message") -and $toolResponse.message -is [string]) {
        $responseMessage = "$($toolResponse.message)".Trim()
    }

    $entries = @()
    $hasResults = $false
    if ($toolResponse.ContainsKey("data") -and $null -ne $toolResponse.data) {
        if ($toolResponse.data -isnot [hashtable]) {
            throw "The structured response contains an invalid ToolResponse data object."
        }
        if ($toolResponse.data.ContainsKey("results")) {
            if ($toolResponse.data.results -isnot [array]) {
                throw "The structured response contains a ToolResponse data.results value that is not an array."
            }
            $entries = @($toolResponse.data.results)
            $hasResults = $true
        }
    }
    if ($toolResponse.succeeded -and -not $hasResults) {
        throw "The successful structured response does not contain a ToolResponse data.results array."
    }

    $results = @{}
    foreach ($entry in $entries) {
        [int] $codeunitId = $entry.codeunitId
        $methodName = "$($entry.methodName)"
        $status = "$($entry.status)"
        $outcome = switch ($status.ToLowerInvariant()) {
            "passed" { "Pass" }
            "failed" { "Fail" }
            "skipped" { "Skip" }
            default { $null }
        }
        if (-not $outcome) {
            throw "Result $codeunitId/$methodName has unknown status '$status'."
        }

        [long] $durationMs = $entry.durationMs
        $message = ""
        $callstackText = ""
        if ($outcome -eq "Fail") {
            $failure = ConvertFrom-AlFailureOutput -Output "$($entry.output)"
            $message = $failure.Message
            $callstackText = $failure.Stacktrace
        }

        $codeunitKey = "$codeunitId"
        if (-not $results.ContainsKey($codeunitKey)) {
            $results[$codeunitKey] = @()
        }
        $results[$codeunitKey] += @{
            MethodName = $methodName
            Outcome    = $outcome
            Ms         = $durationMs
            Message    = $message
            Stacktrace = $callstackText
        }
    }

    return @{
        Results   = $results
        Succeeded = $toolResponse.succeeded
        Message   = $responseMessage
    }
}

<#
.SYNOPSIS
    Creates an AlTool test-groups input file.
.DESCRIPTION
    Writes the JSON file required by `al runtests --testgroups`, containing each codeunit and its
    enabled test methods.
.PARAMETER Codeunits
    Codeunits with Id and Tests properties to serialize.
.OUTPUTS
    [string] Path to the temporary JSON file.
.EXAMPLE
    $codeunits = @([pscustomobject]@{ Id = "130001"; Tests = @("TestOne", "TestTwo") })
    New-AlTestGroupsFile -Codeunits $codeunits

    # Generated JSON:
    # [{ "codeunitId": 130001, "testMethods": ["TestOne", "TestTwo"] }]
#>
function New-AlTestGroupsFile {
    param(
        [Parameter(Mandatory = $true)][object[]] $Codeunits
    )

    $groups = @()
    foreach ($codeunit in $Codeunits) {
        $codeunitIdText = "$($codeunit.Id)"
        [int] $codeunitId = 0
        if ([string]::IsNullOrWhiteSpace($codeunitIdText) -or
            -not [int]::TryParse(
                $codeunitIdText,
                [System.Globalization.NumberStyles]::Integer,
                [System.Globalization.CultureInfo]::InvariantCulture,
                [ref] $codeunitId
            )) {
            throw "Test codeunit ID '$codeunitIdText' must be a valid Int32 value."
        }

        $methods = @($codeunit.Tests | ForEach-Object { "$_" })
        $groups += [ordered]@{
            codeunitId  = $codeunitId
            testMethods = [string[]] $methods
        }
    }

    $testGroupsFile = Join-Path ([System.IO.Path]::GetTempPath()) "altool-testgroups-$([Guid]::NewGuid().ToString('N')).json"
    ConvertTo-Json -InputObject @($groups) -Depth 5 -Compress |
        Set-Content -LiteralPath $testGroupsFile -Encoding UTF8
    return $testGroupsFile
}

<#
.SYNOPSIS
    Runs all enabled test groups for one app through one AlTool connection.
.DESCRIPTION
    Valid structured results are returned for JUnit generation. Invalid structured output terminates
    as one protocol failure.
#>
function Invoke-AlRunTestsBatch {
    param(
        [Parameter(Mandatory = $true)][object[]] $Codeunits,
        [Parameter(Mandatory = $true)][string] $Company,
        [Parameter(Mandatory = $true)][string] $Tenant,
        [Parameter(Mandatory = $true)][hashtable] $Connection
    )

    $testGroupsFile = New-AlTestGroupsFile -Codeunits $Codeunits
    try {
        $alArgs = @(
            'runtests',
            '--testgroups', $testGroupsFile,
            '--company', $Company,
            '--server', $Connection.Server,
            '--serverinstance', $Connection.ServerInstance,
            '--port', "$($Connection.Port)",
            '--environmenttype', 'OnPrem',
            '--authentication', 'UserPassword',
            '--tenant', $Tenant
        )

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $nativeResult = Invoke-AlNativeCommand -FilePath "al" -ArgumentList $alArgs
        $sw.Stop()

        $standardOutputText = ($nativeResult.StandardOutput -join [Environment]::NewLine).Trim()
        $standardErrorText = ($nativeResult.StandardError -join [Environment]::NewLine).Trim()
        if (-not [string]::IsNullOrWhiteSpace($standardErrorText)) {
            OutputDebug -message "al runtests stderr:$([Environment]::NewLine)$standardErrorText"
        }

        if ($nativeResult.ExitCode -notin @(0, 1)) {
            $details = @("al runtests exited with unexpected code $($nativeResult.ExitCode).")
            if (-not [string]::IsNullOrWhiteSpace($standardErrorText)) {
                $details += "stderr: $standardErrorText"
            }
            if (-not [string]::IsNullOrWhiteSpace($standardOutputText)) {
                $details += "stdout: $standardOutputText"
            }
            throw "AlTool process failure. $($details -join [Environment]::NewLine)"
        }

        if ([string]::IsNullOrWhiteSpace($standardOutputText)) {
            if (-not [string]::IsNullOrWhiteSpace($standardErrorText)) {
                throw "al runtests failed: $standardErrorText (exit code $($nativeResult.ExitCode))."
            }
            throw "al runtests returned no structured stdout or stderr (exit code $($nativeResult.ExitCode))."
        }

        try {
            $parsed = ConvertFrom-AlTestGroupsOutput -OutputLines @($nativeResult.StandardOutput)
        }
        catch {
            $details = @($_.Exception.Message, "stdout: $standardOutputText")
            if (-not [string]::IsNullOrWhiteSpace($standardErrorText)) {
                $details += "stderr: $standardErrorText"
            }
            throw "AlTool protocol failure. $($details -join [Environment]::NewLine)"
        }

        if (-not $parsed.Succeeded -and $parsed.Results.Count -eq 0) {
            $details = @()
            if (-not [string]::IsNullOrWhiteSpace($parsed.Message)) {
                $details += $parsed.Message
            }
            if (-not [string]::IsNullOrWhiteSpace($standardErrorText) -and
                -not [string]::Equals($standardErrorText, $parsed.Message, [StringComparison]::OrdinalIgnoreCase)) {
                $details += "stderr: $standardErrorText"
            }
            if ($details.Count -eq 0) {
                $details += "No failure message or stderr was returned."
            }
            throw "al runtests failed: $($details -join [Environment]::NewLine)"
        }

        return @{
            Results    = $parsed.Results
            Succeeded  = [bool] ($parsed.Succeeded -and ($nativeResult.ExitCode -eq 0))
            ElapsedSec = [Math]::Round($sw.Elapsed.TotalSeconds, 3)
        }
    }
    finally {
        Remove-Item -LiteralPath $testGroupsFile -Force -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Appends an AL-Go AnalyzeTests-compatible JUnit <testsuite> for one codeunit to the given
    <testsuites> document.
.PARAMETER Doc
    The JUnit XmlDocument being built.
.PARAMETER TestSuitesNode
    The root <testsuites> element to append to.
.PARAMETER Codeunit
    The codeunit object (.Id, .Name).
.PARAMETER RequestedMethods
    The method names that were requested for this codeunit.
.PARAMETER MethodResults
    The parsed result occurrences for this codeunit.
.PARAMETER ExtensionId
    The extension (app) id.
.PARAMETER AppName
    The app name.
.PARAMETER Hostname
    The runner host name.
.OUTPUTS
    [int] Number of failing result occurrences in this codeunit.
#>
function Add-JUnitTestSuite {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlDocument] $Doc,
        [Parameter(Mandatory = $true)][System.Xml.XmlElement] $TestSuitesNode,
        [Parameter(Mandatory = $true)] $Codeunit,
        [Parameter(Mandatory = $true)][string[]] $RequestedMethods,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]] $MethodResults,
        [Parameter(Mandatory = $true)][string] $ExtensionId,
        [Parameter(Mandatory = $true)][string] $AppName,
        [Parameter(Mandatory = $true)][string] $Hostname
    )

    $ci = [System.Globalization.CultureInfo]::InvariantCulture
    $suiteName = "$($Codeunit.Id) $($Codeunit.Name)"

    $suite = $Doc.CreateElement("testsuite")
    $suite.SetAttribute("name", $suiteName)
    $suite.SetAttribute("timestamp", (Get-Date -Format s))
    $suite.SetAttribute("hostname", $Hostname)

    $props = $Doc.CreateElement("properties")
    $suite.AppendChild($props) | Out-Null
    $extProp = $Doc.CreateElement("property")
    $extProp.SetAttribute("name", "extensionid")
    $extProp.SetAttribute("value", $ExtensionId)
    $props.AppendChild($extProp) | Out-Null
    if ($AppName) {
        $appProp = $Doc.CreateElement("property")
        $appProp.SetAttribute("name", "appName")
        $appProp.SetAttribute("value", $AppName)
        $props.AppendChild($appProp) | Out-Null
    }

    $failed = 0
    $skipped = 0
    $suiteMs = 0.0
    $testCount = 0
    $requestedMethodLookup = @{}
    $resultsByRequestedMethod = @{}
    foreach ($method in $RequestedMethods) {
        $requestedMethodLookup[$method] = $true
        $resultsByRequestedMethod[$method] = @()
    }

    foreach ($res in $MethodResults) {
        $resultName = "$($res.MethodName)"
        $requestedMethod = $null
        if ($requestedMethodLookup.ContainsKey($resultName)) {
            $requestedMethod = $resultName
        }
        elseif ($resultName -match '^([^\[]+)\[(.+)\]$' -and
            $requestedMethodLookup.ContainsKey($Matches[1])) {
            $requestedMethod = $Matches[1]
        }
        if ($null -ne $requestedMethod) {
            $resultsByRequestedMethod[$requestedMethod] += $res
        }
    }

    foreach ($method in $RequestedMethods) {
        $methodResults = @($resultsByRequestedMethod[$method])
        if ($methodResults.Count -eq 0) {
            $tc = $Doc.CreateElement("testcase")
            $tc.SetAttribute("classname", $suiteName)
            $tc.SetAttribute("name", $method)
            # Missing results remain failures in the final JUnit output.
            $tc.SetAttribute("time", "0")
            $failure = $Doc.CreateElement("failure")
            $failure.SetAttribute("message", "No result produced by al runtests")
            $failure.InnerText = ""
            $tc.AppendChild($failure) | Out-Null
            $failed++
            $testCount++
            $suite.AppendChild($tc) | Out-Null
        }
        else {
            foreach ($res in $methodResults) {
                $tc = $Doc.CreateElement("testcase")
                $tc.SetAttribute("classname", $suiteName)
                $tc.SetAttribute("name", "$($res.MethodName)")
                $suiteMs += [double] $res.Ms
                $tc.SetAttribute("time", ([Math]::Round($res.Ms / 1000.0, 3)).ToString($ci))
                switch ($res.Outcome) {
                    'Fail' {
                        $failure = $Doc.CreateElement("failure")
                        $failure.SetAttribute("message", "$($res.Message)")
                        $failure.InnerText = "$($res.Stacktrace)".Replace(";", "`n")
                        $tc.AppendChild($failure) | Out-Null
                        $failed++
                    }
                    'Skip' {
                        $sk = $Doc.CreateElement("skipped")
                        $tc.AppendChild($sk) | Out-Null
                        $skipped++
                    }
                }
                $testCount++
                $suite.AppendChild($tc) | Out-Null
            }
        }
    }

    $suite.SetAttribute("tests", "$testCount")
    $suite.SetAttribute("errors", "0")
    $suite.SetAttribute("failures", "$failed")
    $suite.SetAttribute("skipped", "$skipped")
    $suite.SetAttribute("time", ([Math]::Round($suiteMs / 1000.0, 3)).ToString($ci))

    $TestSuitesNode.AppendChild($suite) | Out-Null
    return $failed
}

<#
.SYNOPSIS
    Runs all of a single app's test codeunits through `al runtests` and writes a JUnit results file.
.DESCRIPTION
    Runs the app in one test-groups batch and appends JUnit output compatible with AL-Go AnalyzeTests.
.PARAMETER ContainerName
    Container hosting the app under test.
.PARAMETER Credential
    Credential used to run tests.
.PARAMETER ExtensionId
    App ID whose tests are executed.
.PARAMETER AppName
    App name included in logs and JUnit output.
.PARAMETER CompanyName
    Company used for the test run. The container default is used when omitted.
.PARAMETER Tenant
    Tenant used for container discovery and AlTool execution.
.PARAMETER TestType
    Optional platform test type used by BcContainerHelper for server-side test enumeration. Supported
    values are UnitTest, IntegrationTest, and Uncategorized. Blank enumerates all test types.
.PARAMETER DisabledTests
    Hashtable entries describing test methods or codeunits excluded from the run.
.PARAMETER JUnitResultFileName
    Required JUnit file to create or append.
.OUTPUTS
    [bool] $true if all executed methods passed; $false otherwise.
#>
function Invoke-AlToolTestRun {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $ContainerName,
        [Parameter(Mandatory = $true)][System.Management.Automation.PSCredential] $Credential,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $ExtensionId,
        [string] $AppName = "",
        [string] $CompanyName = "",
        [string] $Tenant = "default",
        [string] $TestType = "",
        [AllowEmptyCollection()][hashtable[]] $DisabledTests = @(),
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $JUnitResultFileName
    )

    if ([string]::IsNullOrWhiteSpace($ExtensionId)) {
        throw "Invoke-AlToolTestRun requires a nonblank ExtensionId."
    }
    if ([string]::IsNullOrWhiteSpace($JUnitResultFileName)) {
        throw "Invoke-AlToolTestRun requires a nonblank JUnitResultFileName."
    }
    if ([string]::IsNullOrWhiteSpace($Tenant)) {
        $Tenant = "default"
    }

    try {
        $env:BC_SERVER_USERNAME = $Credential.UserName
        $env:BC_SERVER_PASSWORD = $Credential.GetNetworkCredential().Password

        $codeunits = @(Get-AlToolTestCodeunits -ContainerName $ContainerName -Credential $Credential `
                -ExtensionId $ExtensionId -Tenant $Tenant -TestType $TestType -DisabledTests $DisabledTests)
        Write-Host "Enumerated $($codeunits.Count) test codeunit(s) for app '$AppName'."
        if ($codeunits.Count -eq 0) {
            Write-Host "No test codeunits to run for app '$AppName'; nothing to do."
            return $true
        }

        if (-not (Get-Command al -ErrorAction SilentlyContinue)) {
            Install-AlTool | Out-Null
        }

        $connection = Get-AlToolConnection -ContainerName $ContainerName
        $company = Get-AlToolCompany -ContainerName $ContainerName -Tenant $Tenant -CompanyName $CompanyName
        if ([string]::IsNullOrWhiteSpace($company)) {
            throw "Could not resolve a company to run tests against in container '$ContainerName'."
        }

        Write-Host "altool run: app='$AppName' extensionId=$ExtensionId company='$company' server='$($connection.Server)' instance='$($connection.ServerInstance)' port=$($connection.Port) tenant='$Tenant'"

        $hostname = [System.Net.Dns]::GetHostName()

        # Multiple test apps append to the same result file.
        $doc = New-Object System.Xml.XmlDocument
        if (Test-Path -LiteralPath $JUnitResultFileName) {
            try {
                $doc.Load($JUnitResultFileName)
            }
            catch {
                $message = "Could not load existing JUnit file '$JUnitResultFileName': $($_.Exception.Message)"
                throw [System.IO.InvalidDataException]::new($message, $_.Exception)
            }

            $suites = $doc.DocumentElement
            if (-not $suites -or $suites.LocalName -ne 'testsuites') {
                $rootName = if ($suites) { "'$($suites.LocalName)'" } else { "no root element" }
                throw "Existing JUnit file '$JUnitResultFileName' has $rootName; expected a 'testsuites' root element."
            }
        }
        else {
            $doc.AppendChild($doc.CreateXmlDeclaration("1.0", "UTF-8", $null)) | Out-Null
            $suites = $doc.CreateElement("testsuites")
            $doc.AppendChild($suites) | Out-Null
        }

        $batch = Invoke-AlRunTestsBatch -Codeunits $codeunits -Company $company `
            -Tenant $Tenant -Connection $connection
        $batchResults = $batch.Results
        $allPassed = [bool] $batch.Succeeded

        $idx = 0
        foreach ($cu in $codeunits) {
            $idx++
            $methods = @($cu.Tests | ForEach-Object { "$_" })
            $cuResults = $batchResults["$($cu.Id)"]
            if ($null -eq $cuResults) { $cuResults = @() }

            $failed = Add-JUnitTestSuite -Doc $doc -TestSuitesNode $suites -Codeunit $cu `
                -RequestedMethods $methods -MethodResults $cuResults -ExtensionId $ExtensionId `
                -AppName $AppName -Hostname $hostname

            if ($failed -gt 0) { $allPassed = $false }

            Write-Host ("[{0}/{1}] cu {2} '{3}' -> {4} failed result(s) from {5} requested method(s)" -f `
                    $idx, $codeunits.Count, $cu.Id, $cu.Name, $failed, $methods.Count)
        }
        Write-Host ("Run for app '{0}': {1} codeunit(s) in {2}s real al wall-clock." -f `
                $AppName, $codeunits.Count, [Math]::Round([double] $batch.ElapsedSec, 2))

        $dir = [System.IO.Path]::GetDirectoryName($JUnitResultFileName)
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $doc.Save($JUnitResultFileName)
        Write-Host "Wrote JUnit results for app '$AppName' to $JUnitResultFileName"

        return $allPassed
    }
    finally {
        # Do not retain container credentials after the run.
        Remove-Item Env:\BC_SERVER_USERNAME -ErrorAction SilentlyContinue
        Remove-Item Env:\BC_SERVER_PASSWORD -ErrorAction SilentlyContinue
    }
}

Export-ModuleMember -Function Install-AlTool, Invoke-AlToolTestRun
