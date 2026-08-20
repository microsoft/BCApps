# ------------------------------------------------------------------------------
# Vendored from spetersenms/AL-Go @ spetersen/separateTestAction (commit 3885bca).
# Source: Actions/RunTests/AlToolTestRunner.psm1
#
# This is the AL-Go RunTests action's BATCHED altool runner: Invoke-AlToolTestRun
# runs all of a test app's codeunits in a single `al runtests --testgroups` call
# (one shared server session per app), instead of one `al runtests` per codeunit.
#
# BCApps' RunTestsInBcContainer.ps1 override drives this module for the
# IntegrationTest and Uncategorized buckets while keeping BCApps' parallel-tenant
# fan-out, reruns and test tolerance. To refresh, re-copy the file from the AL-Go
# branch above and keep this header.
#
# NOTE: batching reuses one session across a codeunit group, so until altool's
# per-codeunit session renewal ships, expect cross-codeunit state leakage failures
# (e.g. "codeunit ... already been bound" and mock-provider poisoning) that the
# previous per-codeunit runner did not exhibit.
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
    Keeps stdout separate from native stderr under Windows PowerShell 5 and restores the caller's
    error preference immediately after invocation. Command resolution and invocation failures remain
    terminating.
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
    $errorBeforeInvocation = if ($Error.Count -gt 0) { $Error[0] } else { $null }
    $originalErrorActionPreference = $ErrorActionPreference
    $nativeErrorPreference = Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue
    $originalNativeErrorPreference = if ($nativeErrorPreference) { $nativeErrorPreference.Value } else { $null }
    try {
        try {
            $ErrorActionPreference = "Continue"
            if ($nativeErrorPreference) {
                $PSNativeCommandUseErrorActionPreference = $false
            }
            if ($PSVersionTable.PSVersion.Major -le 5) {
                $nativeOutput = & $nativeCommand.Source @ArgumentList 2>&1
                [int] $exitCode = $LASTEXITCODE
            }
            else {
                $standardOutput = & $nativeCommand.Source @ArgumentList 2> $standardErrorPath
                [int] $exitCode = $LASTEXITCODE
            }
        }
        finally {
            $ErrorActionPreference = $originalErrorActionPreference
            if ($nativeErrorPreference) {
                $PSNativeCommandUseErrorActionPreference = $originalNativeErrorPreference
            }
        }

        $invocationErrors = @()
        foreach ($errorRecord in $Error) {
            if ($null -ne $errorBeforeInvocation -and [object]::ReferenceEquals($errorRecord, $errorBeforeInvocation)) {
                break
            }
            if ($errorRecord.FullyQualifiedErrorId -notin @("NativeCommandError", "NativeCommandErrorMessage")) {
                $invocationErrors += $errorRecord
            }
        }
        if ($invocationErrors.Count -gt 0) {
            throw $invocationErrors[0]
        }

        if ($PSVersionTable.PSVersion.Major -le 5) {
            [string[]] $standardOutputLines = @($nativeOutput |
                Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } |
                ForEach-Object { "$_" })
            [string[]] $standardErrorLines = @($nativeOutput |
                Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } |
                ForEach-Object { "$($_.Exception.Message)" })
        }
        else {
            [string[]] $standardOutputLines = @($standardOutput | ForEach-Object { "$_" })
            if (Test-Path -LiteralPath $standardErrorPath) {
                [string[]] $standardErrorLines = @(Get-Content -LiteralPath $standardErrorPath | ForEach-Object { "$_" })
            }
            else {
                [string[]] $standardErrorLines = @()
            }
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
    param(
        [switch] $Force
    )

    $toolsPath = Join-Path $env:USERPROFILE ".dotnet\tools"
    if ($env:HOME -and -not $env:USERPROFILE) {
        $toolsPath = Join-Path $env:HOME ".dotnet/tools"
    }
    if (($env:PATH -split [System.IO.Path]::PathSeparator) -notcontains $toolsPath) {
        $env:PATH = "$env:PATH$([System.IO.Path]::PathSeparator)$toolsPath"
    }

    # Serialize install/update across processes with a named mutex and re-check availability after
    # acquiring it (another job may have just installed it).
    $mutex = New-Object System.Threading.Mutex($false, "Global\AL-Go-AlTool-Install")
    $acquired = $false
    try {
        try { $acquired = $mutex.WaitOne([TimeSpan]::FromMinutes(10)) } catch [System.Threading.AbandonedMutexException] { $acquired = $true }

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
        elseif ($Force) {
            # Explicit opt-in moves to the newest prerelease once, under the mutex.
            try {
                $updateResult = Invoke-AlNativeCommand -FilePath "dotnet" -ArgumentList @(
                    "tool", "update", $script:AlToolPackageId, "--global", "--prerelease"
                )
                $updateResult.Output | ForEach-Object { Write-Host $_ }
                if ($updateResult.ExitCode -ne 0) {
                    Write-Host "WARNING: 'al' update check exited with code $($updateResult.ExitCode). Using existing version."
                }
            }
            catch {
                Write-Host "WARNING: 'al' update check failed ($($_.Exception.Message)). Using existing version."
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
    Creates the temporary AL project used to connect AlTool to the container.
.PARAMETER ContainerName
    The name of the build container.
.PARAMETER Tenant
    The tenant to connect to.
.PARAMETER Connection
    The connection hashtable produced by Get-AlToolConnection.
.OUTPUTS
    [string] Path to the generated project folder.
#>
function New-AlToolProject {
    param(
        [Parameter(Mandatory = $true)][string] $ContainerName,
        [Parameter(Mandatory = $true)][string] $Tenant,
        [Parameter(Mandatory = $true)][hashtable] $Connection
    )

    $projectRoot = Join-Path ([System.IO.Path]::GetTempPath()) "altool-project-$ContainerName"
    $vscodeDir = Join-Path $projectRoot ".vscode"
    New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null

    $appJson = [ordered]@{
        id        = [System.Guid]::NewGuid().ToString()
        name      = "AlToolTestDriver"
        publisher = "AL-Go"
        version   = "1.0.0.0"
        platform  = "1.0.0.0"
        runtime   = "15.0"
    }
    $appJson | ConvertTo-Json | Set-Content -Path (Join-Path $projectRoot "app.json") -Encoding UTF8

    $launch = [ordered]@{
        version        = "0.2.0"
        configurations = @(
            [ordered]@{
                name              = "altool"
                type              = "al"
                request           = "launch"
                server            = $Connection.Server
                serverInstance    = $Connection.ServerInstance
                port              = $Connection.Port
                tenant            = $Tenant
                authentication    = "UserPassword"
                environmentType   = "OnPrem"
                startupObjectId   = 22
                startupObjectType = "Page"
                schemaUpdateMode  = "Synchronize"
            }
        )
    }
    $launch | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $vscodeDir "launch.json") -Encoding UTF8

    return $projectRoot
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
    Array of disabled-test entries.
.OUTPUTS
    [hashtable] @{ Methods = <set of "<codeunitname>::<method>">; Codeunits = <set of "<codeunitname>"> }
#>
function Get-DisabledTestKeySet {
    param(
        [array] $DisabledTests = @()
    )

    $methodSet = @{}
    $codeunitSet = @{}
    foreach ($entry in $DisabledTests) {
        if (-not $entry) { continue }
        $cuName = "$($entry.codeunitName)".ToLowerInvariant()
        $methods = @()
        if ($entry.PSObject.Properties['method'] -and $entry.method) { $methods = @($entry.method) }
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
    Optional BcContainerHelper test type filter.
.PARAMETER DisabledTests
    Test methods or codeunits excluded from the run.
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
        [AllowEmptyCollection()][object[]] $DisabledTests = @()
    )

    $getTestsParams = @{
        containerName = $ContainerName
        tenant        = $Tenant
        credential    = $Credential
        extensionId   = $ExtensionId
        ignoreGroups  = $true
    }
    if (-not [string]::IsNullOrWhiteSpace($TestType)) {
        $getTestsParams.testType = $TestType
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
    Parses an AlTool test-groups response into codeunit and method result maps.
.DESCRIPTION
    Valid batch entries are retained even when other entries are invalid or missing.
.PARAMETER OutputLines
    The complete structured stdout from `al runtests --testgroups`.
.OUTPUTS
    [hashtable] containing Results, HasFailedOutcome, Parsed, Issues, and ParseError.
#>
function ConvertFrom-AlTestGroupsOutput {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][AllowEmptyString()][string[]] $OutputLines
    )

    $result = @{
        Results          = @{}
        HasFailedOutcome = $false
        Parsed           = $false
        Issues           = @()
        ParseError       = ""
    }
    $json = ($OutputLines -join [Environment]::NewLine).Trim()
    if ([string]::IsNullOrWhiteSpace($json)) {
        $result.ParseError = "The command returned no structured stdout."
        return $result
    }

    try {
        $toolResponse = ConvertTo-HashTable -object ($json | ConvertFrom-Json) -recurse
    }
    catch {
        $result.ParseError = "The structured stdout could not be parsed as JSON: $($_.Exception.Message)"
        return $result
    }

    if ($toolResponse -isnot [hashtable] -or
        -not $toolResponse.ContainsKey("succeeded") -or $toolResponse.succeeded -isnot [bool] -or
        -not $toolResponse.ContainsKey("data") -or $toolResponse.data -isnot [hashtable] -or
        -not $toolResponse.data.ContainsKey("results") -or $null -eq $toolResponse.data.results) {
        $result.ParseError = "The structured response does not contain a valid ToolResponse data.results collection."
        return $result
    }

    $result.Parsed = $true
    $invalidResults = @{}
    foreach ($entry in @($toolResponse.data.results)) {
        if ($entry -isnot [hashtable]) {
            $result.Issues += "A result entry is not an object."
            continue
        }

        $codeunitId = 0
        if (-not [int]::TryParse("$($entry.codeunitId)", [ref] $codeunitId) -or $codeunitId -le 0) {
            $result.Issues += "A result entry has an invalid codeunitId '$($entry.codeunitId)'."
            continue
        }
        $methodName = "$($entry.methodName)"
        if ([string]::IsNullOrWhiteSpace($methodName)) {
            $result.Issues += "A result entry for codeunit $codeunitId has no methodName."
            continue
        }

        $outcome = switch ("$($entry.status)".ToLowerInvariant()) {
            "passed" { "Pass" }
            "failed" { "Fail" }
            "skipped" { "Skip" }
            default { $null }
        }
        if (-not $outcome) {
            $result.Issues += "Result $codeunitId/$methodName has unknown status '$($entry.status)'."
            continue
        }
        if ($outcome -eq "Fail") {
            $result.HasFailedOutcome = $true
        }

        $durationMs = 0
        if ($entry.ContainsKey("durationMs") -and $null -ne $entry.durationMs -and
            -not [int]::TryParse("$($entry.durationMs)", [ref] $durationMs)) {
            $result.Issues += "Result $codeunitId/$methodName has invalid durationMs '$($entry.durationMs)'; using zero."
            $durationMs = 0
        }

        $message = ""
        $callstackText = ""
        if ($outcome -eq "Fail") {
            $failure = ConvertFrom-AlFailureOutput -Output "$($entry.output)"
            $message = $failure.Message
            $callstackText = $failure.Stacktrace
        }

        $codeunitKey = "$codeunitId"
        $resultKey = "$codeunitKey::$methodName"
        if ($invalidResults.ContainsKey($resultKey)) {
            continue
        }
        if (-not $result.Results.ContainsKey($codeunitKey)) {
            $result.Results[$codeunitKey] = @{}
        }
        if ($result.Results[$codeunitKey].ContainsKey($methodName)) {
            $result.Results[$codeunitKey].Remove($methodName)
            $invalidResults[$resultKey] = $true
            $result.Issues += "The response contains duplicate results for $codeunitId/$methodName; the result was invalidated."
            continue
        }
        $result.Results[$codeunitKey][$methodName] = @{
            Outcome    = $outcome
            Ms         = $durationMs
            Message    = $message
            Stacktrace = $callstackText
        }
    }

    return $result
}

function New-AlTestGroupsFile {
    param(
        [Parameter(Mandatory = $true)][object[]] $Codeunits
    )

    $groups = @()
    $seenCodeunits = @{}
    foreach ($codeunit in $Codeunits) {
        $codeunitId = 0
        if (-not [int]::TryParse("$($codeunit.Id)", [ref] $codeunitId) -or $codeunitId -le 0) {
            throw "AlTool test codeunit id '$($codeunit.Id)' must be a positive integer."
        }
        if ($seenCodeunits.ContainsKey("$codeunitId")) {
            throw "AlTool test codeunit id '$codeunitId' was enumerated more than once."
        }
        $seenCodeunits["$codeunitId"] = $true
        $methods = @($codeunit.Tests | ForEach-Object { "$_" })
        if ($methods.Count -eq 0) { continue }
        $groups += [ordered]@{
            codeunitId = $codeunitId
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
    Valid structured results are returned for JUnit generation. Invalid result entries are reported.
#>
function Invoke-AlRunTestsBatch {
    param(
        [Parameter(Mandatory = $true)][object[]] $Codeunits,
        [Parameter(Mandatory = $true)][string] $ProjectPath,
        [Parameter(Mandatory = $true)][string] $Company,
        [Parameter(Mandatory = $true)][string] $Tenant,
        [Parameter(Mandatory = $true)][hashtable] $Connection
    )

    $testGroupsFile = New-AlTestGroupsFile -Codeunits $Codeunits
    try {
        $alArgs = @(
            'runtests',
            '--testgroups', $testGroupsFile,
            '--project', $ProjectPath,
            '--company', $Company,
            '--server', $Connection.Server,
            '--serverinstance', $Connection.ServerInstance,
            '--port', "$($Connection.Port)",
            '--environmenttype', 'OnPrem',
            '--authentication', 'UserPassword',
            '--tenant', $Tenant
        )

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $nativeResult = Invoke-AlNativeCommand -FilePath "al" -ArgumentList $alArgs
        }
        finally {
            $sw.Stop()
        }

        $parsed = ConvertFrom-AlTestGroupsOutput -OutputLines @($nativeResult.StandardOutput)
        $protocolErrors = @()
        if ($nativeResult.ExitCode -notin @(0, 1)) {
            $protocolErrors += "The command exited with unexpected code $($nativeResult.ExitCode)."
        }
        if (-not $parsed.Parsed) {
            $protocolErrors += $parsed.ParseError
        }
        else {
            if ($nativeResult.ExitCode -eq 1 -and -not $parsed.HasFailedOutcome) {
                $protocolErrors += "The command exited with code 1 without reporting a failed test."
            }
            if ($nativeResult.ExitCode -eq 0 -and $parsed.HasFailedOutcome) {
                $protocolErrors += "The command exited with code 0 after reporting a failed test."
            }
        }

        if ($protocolErrors.Count -gt 0) {
            $diagnostics = @()
            if ($nativeResult.StandardError.Count -gt 0) {
                $diagnostics += "stderr: $($nativeResult.StandardError -join [Environment]::NewLine)"
            }
            if ($nativeResult.StandardOutput.Count -gt 0) {
                $diagnostics += "stdout: $($nativeResult.StandardOutput -join [Environment]::NewLine)"
            }
            if ($diagnostics.Count -eq 0) {
                $diagnostics += "The command produced no stdout or stderr."
            }
            throw "AlTool test batch protocol failure. $($protocolErrors -join ' ') $($diagnostics -join [Environment]::NewLine)"
        }

        if ($parsed.Issues.Count -gt 0) {
            Write-Host "::warning::The AlTool test batch contained invalid result entries. $($parsed.Issues -join ' ')"
            if ($nativeResult.StandardError.Count -gt 0) {
                Write-Host "al runtests stderr:"
                Write-Host ($nativeResult.StandardError -join [Environment]::NewLine)
            }
            if ($nativeResult.StandardOutput.Count -gt 0) {
                Write-Host "al runtests stdout:"
                Write-Host ($nativeResult.StandardOutput -join [Environment]::NewLine)
            }
        }

        return @{
            Results    = $parsed.Results
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
    The parsed per-method result map for this codeunit.
.PARAMETER ExtensionId
    The extension (app) id.
.PARAMETER AppName
    The app name.
.PARAMETER Hostname
    The runner host name.
.OUTPUTS
    [int] Number of failing methods in this codeunit.
#>
function Add-JUnitTestSuite {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlDocument] $Doc,
        [Parameter(Mandatory = $true)][System.Xml.XmlElement] $TestSuitesNode,
        [Parameter(Mandatory = $true)] $Codeunit,
        [Parameter(Mandatory = $true)][string[]] $RequestedMethods,
        [Parameter(Mandatory = $true)][hashtable] $MethodResults,
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
    foreach ($method in $RequestedMethods) {
        $res = $MethodResults[$method]

        $tc = $Doc.CreateElement("testcase")
        $tc.SetAttribute("classname", $suiteName)
        $tc.SetAttribute("name", $method)

        if ($null -eq $res) {
            # Missing results remain failures in the final JUnit output.
            $tc.SetAttribute("time", "0")
            $failure = $Doc.CreateElement("failure")
            $failure.SetAttribute("message", "No result produced by al runtests")
            $failure.InnerText = ""
            $tc.AppendChild($failure) | Out-Null
            $failed++
        }
        else {
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
        }
        $suite.AppendChild($tc) | Out-Null
    }

    $suite.SetAttribute("tests", "$($RequestedMethods.Count)")
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
.PARAMETER DisabledTests
    Test methods or codeunits excluded from the run.
.PARAMETER TestType
    Optional BcContainerHelper test type filter.
.PARAMETER JUnitResultFileName
    JUnit file to create or append.
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
        [AllowEmptyCollection()][object[]] $DisabledTests = @(),
        [string] $TestType = "",
        [string] $JUnitResultFileName = ""
    )

    if ([string]::IsNullOrWhiteSpace($ExtensionId)) {
        throw "Invoke-AlToolTestRun requires a nonblank ExtensionId."
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
        $projectPath = New-AlToolProject -ContainerName $ContainerName -Tenant $Tenant -Connection $connection
        $company = Get-AlToolCompany -ContainerName $ContainerName -Tenant $Tenant -CompanyName $CompanyName
        if ([string]::IsNullOrWhiteSpace($company)) {
            throw "Could not resolve a company to run tests against in container '$ContainerName'."
        }

        Write-Host "altool run: app='$AppName' extensionId=$ExtensionId company='$company' server='$($connection.Server)' instance='$($connection.ServerInstance)' port=$($connection.Port) tenant='$Tenant'"

        $hostname = [System.Net.Dns]::GetHostName()

        # Multiple test apps append to the same result file.
        $doc = New-Object System.Xml.XmlDocument
        $suites = $null
        if (-not [string]::IsNullOrWhiteSpace($JUnitResultFileName) -and (Test-Path $JUnitResultFileName)) {
            try {
                $doc.Load($JUnitResultFileName)
                $suites = $doc.DocumentElement
                if (-not $suites -or $suites.LocalName -ne 'testsuites') { $suites = $null; $doc = New-Object System.Xml.XmlDocument }
            }
            catch {
                Write-Host "WARNING: Could not load existing JUnit file '$JUnitResultFileName' ($($_.Exception.Message)); starting fresh."
                $doc = New-Object System.Xml.XmlDocument
                $suites = $null
            }
        }
        if (-not $suites) {
            $doc.AppendChild($doc.CreateXmlDeclaration("1.0", "UTF-8", $null)) | Out-Null
            $suites = $doc.CreateElement("testsuites")
            $doc.AppendChild($suites) | Out-Null
        }

        $allPassed = $true

        $batch = Invoke-AlRunTestsBatch -Codeunits $codeunits -ProjectPath $projectPath `
            -Company $company -Tenant $Tenant -Connection $connection
        $batchResults = $batch.Results

        $idx = 0
        foreach ($cu in $codeunits) {
            $idx++
            $methods = @($cu.Tests | ForEach-Object { "$_" })
            $cuResults = $batchResults["$($cu.Id)"]
            if ($null -eq $cuResults) { $cuResults = @{} }

            $failed = Add-JUnitTestSuite -Doc $doc -TestSuitesNode $suites -Codeunit $cu `
                -RequestedMethods $methods -MethodResults $cuResults -ExtensionId $ExtensionId `
                -AppName $AppName -Hostname $hostname

            if ($failed -gt 0) { $allPassed = $false }

            Write-Host ("[{0}/{1}] cu {2} '{3}' -> {4} failed of {5} method(s)" -f `
                    $idx, $codeunits.Count, $cu.Id, $cu.Name, $failed, $methods.Count)
        }
        Write-Host ("Run for app '{0}': {1} codeunit(s) in {2}s real al wall-clock." -f `
                $AppName, $codeunits.Count, [Math]::Round([double] $batch.ElapsedSec, 2))

        if (-not [string]::IsNullOrWhiteSpace($JUnitResultFileName)) {
            $dir = [System.IO.Path]::GetDirectoryName($JUnitResultFileName)
            if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            $doc.Save($JUnitResultFileName)
            Write-Host "Wrote JUnit results for app '$AppName' to $JUnitResultFileName"
        }
        else {
            Write-Host "WARNING: No JUnitResultFileName in parameters; results not persisted for app '$AppName'."
        }

        return $allPassed
    }
    finally {
        # Do not retain container credentials after the run.
        Remove-Item Env:\BC_SERVER_USERNAME -ErrorAction SilentlyContinue
        Remove-Item Env:\BC_SERVER_PASSWORD -ErrorAction SilentlyContinue
    }
}

Export-ModuleMember -Function Install-AlTool, Invoke-AlToolTestRun
