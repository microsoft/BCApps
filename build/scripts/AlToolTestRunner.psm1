# Vendored verbatim from AL-Go's RunTests action (Actions/RunTests/AlToolTestRunner.psm1). This is
# Microsoft's public, non-batched `al runtests` runner. BCApps drives it from the shared
# RunTestsInBcContainer.ps1 override for the IntegrationTest and Uncategorized buckets so those
# buckets run on altool while keeping BCApps' parallel-tenant fan-out, reruns and test tolerance.
# UnitTest and Legacy buckets stay on the BCH runner. Keep this file in sync with the AL-Go source
# rather than editing it locally.

<#
.SYNOPSIS
    Built-in test runner that drives Microsoft's headless `al runtests` (altool) CLI instead of
    BcContainerHelper's client-session runner, while producing the same JUnit XML the AL-Go
    pipeline already consumes downstream.

.DESCRIPTION
    This module is the default test runner used by the RunTests action (Invoke-AlGoTestRun) when no
    RunTestsInBcContainer override script is supplied. For a single test app (identified by
    extensionId) it:
      1. Ensures the `al` CLI is installed (dotnet global tool, prerelease).
      2. Resolves the kept-alive container's on-prem connection settings (server/instance/port)
         host-side from the container name via BcContainerHelper, and generates a throw-away AL
         project with a launch.json so `al runtests` has connection settings.
      3. Enumerates the app's test codeunits + methods via Get-TestsFromBcContainer.
      4. Runs `al runtests <codeunitId> --testmethods` once per test codeunit (each in its own
         session), with a rerun pass that retries any method that produced no result or a failure.
      5. Emits a JUnit results file matching the exact schema BcContainerHelper produces, so the
         downstream AnalyzeTests step keeps working unchanged.

    Credentials are taken from the parameters' PSCredential and exposed to `al` through the
    BC_SERVER_USERNAME / BC_SERVER_PASSWORD environment variables (the only auth mechanism the CLI
    supports for on-prem UserPassword).

    Known altool output quirks handled here:
      - The Results: block emits a phantom `PASS OnRun (..)` trigger entry and a trailing
        empty-named aggregate entry per codeunit; both are dropped so counts match the real methods.
      - Failure text is the indented lines after `FAIL <name> (Nms)` up to `AL Callstack:`; the
        callstack follows until the next result line.
#>

$ErrorActionPreference = "Stop"

$script:AlToolPackageId = "Microsoft.Dynamics.BusinessCentral.Development.Tools"

<#
.SYNOPSIS
    Ensures the `al` CLI is available on PATH, installing the prerelease dotnet global tool.
.DESCRIPTION
    Installs (or, when already present, leaves in place) the AL developer tools as a dotnet global
    tool. The install is guarded by a named mutex so concurrent jobs on the same runner do not
    collide on the shared tools store, and availability is re-checked after acquiring the mutex.
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
            & dotnet tool install $script:AlToolPackageId --global --prerelease *>&1 | ForEach-Object { Write-Host $_ }
            if ($LASTEXITCODE -ne 0) {
                # A concurrent job may have installed it first; treat as success if `al` now resolves,
                # otherwise fall back to an update.
                if ($null -eq (Get-Command al -ErrorAction SilentlyContinue)) {
                    & dotnet tool update $script:AlToolPackageId --global --prerelease *>&1 | ForEach-Object { Write-Host $_ }
                }
            }
        }
        elseif ($Force) {
            # Explicit opt-in moves to the newest prerelease once, under the mutex.
            try {
                & dotnet tool update $script:AlToolPackageId --global --prerelease *>&1 | ForEach-Object { Write-Host $_ }
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

    $version = (& al --version 2>&1 | Select-Object -First 1)
    Write-Host "Using al CLI version: $version"
    return "$version"
}

<#
.SYNOPSIS
    Resolves the on-prem connection settings (server URL, instance, dev-service port) for a container.
.DESCRIPTION
    BcContainerHelper's Run-TestsInBcContainer only needs the container name and resolves the
    endpoint internally, but `al runtests` needs an explicit server/instance/port. This reads them
    host-side from the container's server configuration, falling back to conventional defaults.
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
    Creates a throw-away AL project folder with a launch.json targeting the container so `al runtests`
    can resolve connection settings.
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
    Honors an explicitly requested company name first, then falls back to the container's default
    (preferring an evaluation company) via Get-CompanyInBcContainer.
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
    Builds disabled-test lookups from the disabledTests list: per-method keys plus whole-codeunit
    names (where a `*` wildcard method disables the entire codeunit).
.DESCRIPTION
    Each disabledTests entry has a codeunitName and either a single 'method', an array of methods, or
    the wildcard '*'. A '*' entry means the ENTIRE codeunit is disabled, so it must exclude every
    method of that codeunit - not a literal method named '*'. Names/keys are lowercased for
    case-insensitive matching.
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
    Enumerates the test codeunits + enabled methods for an app in the container.
.DESCRIPTION
    Uses Get-TestsFromBcContainer with the app's extensionId to list every test codeunit and method.
    When a disabledTests list is supplied, disabled methods (and whole codeunits marked with a `*`
    wildcard) are filtered out here, because `al runtests` has no equivalent of BCH's run-time
    DisableTestMethod control.
.PARAMETER Parameters
    Hashtable with containerName, tenant, credential, extensionId and optionally testType and
    disabledTests.
.OUTPUTS
    [object[]] Codeunit objects with .Id, .Name, .Tests (enabled method name array).
#>
function Get-AlToolTestCodeunits {
    param(
        [Parameter(Mandatory = $true)][hashtable] $Parameters
    )

    $getTestsParams = @{
        containerName = $Parameters.containerName
        tenant        = if ($Parameters.ContainsKey("tenant") -and $Parameters.tenant) { $Parameters.tenant } else { "default" }
        credential    = $Parameters.credential
        extensionId   = $Parameters.extensionId
        ignoreGroups  = $true
    }
    if ($Parameters.ContainsKey("testType") -and $Parameters.testType) {
        $getTestsParams.testType = $Parameters.testType
    }

    $codeunits = @(Get-TestsFromBcContainer @getTestsParams)

    $disabledMethods = @{}
    $disabledCodeunits = @{}
    if ($Parameters.ContainsKey("disabledTests") -and $Parameters.disabledTests) {
        $lookup = Get-DisabledTestKeySet -DisabledTests @($Parameters.disabledTests)
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

<#
.SYNOPSIS
    Parses the `Results:` block of a single `al runtests` invocation into per-method outcomes.
.DESCRIPTION
    Drops the phantom `OnRun` trigger entry and the trailing empty-named aggregate entry. Captures
    the failure message (lines up to `AL Callstack:`) and callstack (following lines) for failures.
.PARAMETER OutputLines
    The lines of `al runtests --raw` output.
.OUTPUTS
    [hashtable] method name -> @{ Outcome (Pass/Fail/Skip); Ms; Message; Stacktrace }
#>
function ConvertFrom-AlRunTestsOutput {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][AllowEmptyString()][string[]] $OutputLines
    )

    $results = @{}
    $resultLineRegex = '^\s*(PASS|FAIL|SKIP)\s+(.*?)\s*\((\d+)ms\)\s*$'

    $startIdx = -1
    for ($i = 0; $i -lt $OutputLines.Count; $i++) {
        if ($OutputLines[$i] -match '^\s*Results:\s*$') { $startIdx = $i + 1; break }
    }
    if ($startIdx -lt 0) { return $results }

    $i = $startIdx
    while ($i -lt $OutputLines.Count) {
        $line = $OutputLines[$i]
        $m = [regex]::Match($line, $resultLineRegex)
        if (-not $m.Success) { $i++; continue }

        $outcome = switch ($m.Groups[1].Value) { 'PASS' { 'Pass' } 'FAIL' { 'Fail' } 'SKIP' { 'Skip' } }
        $name = $m.Groups[2].Value.Trim()
        $ms = [int]$m.Groups[3].Value

        if ([string]::IsNullOrWhiteSpace($name) -or $name -eq 'OnRun') { $i++; continue }

        $message = ''
        $stackText = ''
        if ($outcome -eq 'Fail') {
            $msgLines = @()
            $stackLines = @()
            $inStack = $false
            $j = $i + 1
            while ($j -lt $OutputLines.Count) {
                $next = $OutputLines[$j]
                if ([regex]::IsMatch($next, $resultLineRegex)) { break }
                if ($next -match '^\s*AL Callstack:\s*$') { $inStack = $true; $j++; continue }
                if ($inStack) {
                    if ($next.Trim().Length -gt 0) { $stackLines += $next.Trim() }
                }
                else {
                    if ($next.Trim().Length -gt 0) { $msgLines += $next.Trim() }
                }
                $j++
            }
            $message = ($msgLines -join ' ').Trim()
            $stackText = ($stackLines -join ';')
            $i = $j
        }
        else {
            $i++
        }

        $results[$name] = @{ Outcome = $outcome; Ms = $ms; Message = $message; Stacktrace = $stackText }
    }

    return $results
}

<#
.SYNOPSIS
    Runs `al runtests` for one codeunit and returns the parsed per-method results plus raw output.
.PARAMETER CodeunitId
    The codeunit id to run.
.PARAMETER Methods
    The test method names to run.
.PARAMETER ProjectPath
    The throw-away AL project folder.
.PARAMETER Company
    The company to run against.
.PARAMETER Tenant
    The tenant to connect to.
.PARAMETER Connection
    The connection hashtable produced by Get-AlToolConnection.
.OUTPUTS
    [hashtable] @{ Results (method->outcome map); ElapsedSec; Raw; Connected (bool) }
#>
function Invoke-AlRunTestsForCodeunit {
    param(
        [Parameter(Mandatory = $true)][string] $CodeunitId,
        [Parameter(Mandatory = $true)][string[]] $Methods,
        [Parameter(Mandatory = $true)][string] $ProjectPath,
        [Parameter(Mandatory = $true)][string] $Company,
        [Parameter(Mandatory = $true)][string] $Tenant,
        [Parameter(Mandatory = $true)][hashtable] $Connection
    )

    # `al runtests` emits structured JSON by default in newer builds; `--raw` restores the
    # human-readable text summary ("Test run completed: ..." + a "Results:" block of
    # "PASS|FAIL|SKIP <name> (Nms)" lines) that ConvertFrom-AlRunTestsOutput parses.
    $alArgs = @(
        'runtests', $CodeunitId,
        '--project', $ProjectPath,
        '--company', $Company,
        '--server', $Connection.Server,
        '--serverinstance', $Connection.ServerInstance,
        '--port', "$($Connection.Port)",
        '--environmenttype', 'OnPrem',
        '--authentication', 'UserPassword',
        '--tenant', $Tenant,
        '--raw',
        '--testmethods'
    ) + $Methods

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $output = & al @alArgs 2>&1
    $sw.Stop()

    $lines = @($output | ForEach-Object { "$_" })
    $connected = ($lines | Where-Object { $_ -match 'Test run completed:' }).Count -gt 0
    $parsed = ConvertFrom-AlRunTestsOutput -OutputLines $lines

    if ($connected -and $parsed.Count -eq 0 -and $Methods.Count -gt 0) {
        Write-Host "::warning::al runtests connected for codeunit $CodeunitId but produced no parseable results. Raw output follows (possible output-format change):"
        Write-Host ($lines -join "`n")
    }

    return @{
        Results    = $parsed
        ElapsedSec = [Math]::Round($sw.Elapsed.TotalSeconds, 3)
        Raw        = ($lines -join "`n")
        Connected  = $connected
    }
}

<#
.SYNOPSIS
    Appends a JUnit <testsuite> for one codeunit to the given <testsuites> document, matching the
    exact schema BcContainerHelper produces.
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
.PARAMETER ElapsedSec
    The elapsed time (seconds) attributed to this codeunit.
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
        [Parameter(Mandatory = $true)][string] $Hostname,
        [Parameter(Mandatory = $true)][double] $ElapsedSec
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
    foreach ($method in $RequestedMethods) {
        $res = $MethodResults[$method]

        $tc = $Doc.CreateElement("testcase")
        $tc.SetAttribute("classname", $suiteName)
        $tc.SetAttribute("name", $method)

        if ($null -eq $res) {
            # Method was requested but the runner produced no result (e.g. connect failure) -> error.
            $tc.SetAttribute("time", "0")
            $failure = $Doc.CreateElement("failure")
            $failure.SetAttribute("message", "No result produced by al runtests")
            $failure.InnerText = ""
            $tc.AppendChild($failure) | Out-Null
            $failed++
        }
        else {
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
    $suite.SetAttribute("time", ([Math]::Round($ElapsedSec, 3)).ToString($ci))

    $TestSuitesNode.AppendChild($suite) | Out-Null
    return $failed
}

<#
.SYNOPSIS
    Runs all of a single app's test codeunits through `al runtests` and writes a JUnit results file.
.DESCRIPTION
    The built-in default test runner for the RunTests action. Expects $Parameters to contain
    containerName, credential, extensionId and (optionally) tenant, companyName, appName,
    disabledTests and JUnitResultFileName. Runs each of the app's test codeunits in its own
    `al runtests` invocation, then re-runs any method that produced no result or a failure once,
    and appends a BcContainerHelper-schema JUnit result. Returns whether every executed method
    passed.
.PARAMETER Parameters
    The BcContainerHelper-shaped test parameters built by Invoke-AlGoTestRun.
.OUTPUTS
    [bool] $true if all executed methods passed; $false otherwise.
#>
function Invoke-AlToolTestRun {
    param(
        [Parameter(Mandatory = $true)][hashtable] $Parameters
    )

    Install-AlTool | Out-Null

    $containerName = $Parameters.containerName
    $tenant = if ($Parameters.ContainsKey("tenant") -and $Parameters.tenant) { "$($Parameters.tenant)" } else { "default" }
    $extensionId = "$($Parameters.extensionId)"
    $appName = if ($Parameters.ContainsKey("appName")) { "$($Parameters.appName)" } else { "" }
    $companyName = if ($Parameters.ContainsKey("companyName")) { "$($Parameters.companyName)" } else { "" }

    if ([string]::IsNullOrWhiteSpace($extensionId)) {
        throw "Invoke-AlToolTestRun requires 'extensionId' in parameters."
    }

    # Expose credentials to the al CLI (only auth channel it supports for on-prem UserPassword).
    # Set inside the try below so the finally always clears them from the process environment.
    if ($Parameters.credential -isnot [System.Management.Automation.PSCredential]) {
        throw "Invoke-AlToolTestRun requires a PSCredential in parameters.credential."
    }

    try {
        $env:BC_SERVER_USERNAME = $Parameters.credential.UserName
        $env:BC_SERVER_PASSWORD = $Parameters.credential.GetNetworkCredential().Password

        $connection = Get-AlToolConnection -ContainerName $containerName
        $projectPath = New-AlToolProject -ContainerName $containerName -Tenant $tenant -Connection $connection
        $company = Get-AlToolCompany -ContainerName $containerName -Tenant $tenant -CompanyName $companyName
        if ([string]::IsNullOrWhiteSpace($company)) {
            throw "Could not resolve a company to run tests against in container '$containerName'."
        }

        Write-Host "altool run: app='$appName' extensionId=$extensionId company='$company' server='$($connection.Server)' instance='$($connection.ServerInstance)' port=$($connection.Port) tenant='$tenant'"

        $codeunits = @(Get-AlToolTestCodeunits -Parameters $Parameters)
        Write-Host "Enumerated $($codeunits.Count) test codeunit(s) for app '$appName'."
        if ($codeunits.Count -eq 0) {
            Write-Host "No test codeunits to run for app '$appName'; nothing to do."
            return $true
        }

        $hostname = [System.Net.Dns]::GetHostName()

        # Append to an existing JUnit file when present (Invoke-AlGoTestRun runs one app at a time
        # into the same TestResults.xml), matching BCH's AppendToJUnitResultFile behavior.
        $junitFile = if ($Parameters.ContainsKey("JUnitResultFileName")) { $Parameters.JUnitResultFileName } else { "" }
        $doc = New-Object System.Xml.XmlDocument
        $suites = $null
        if (-not [string]::IsNullOrWhiteSpace($junitFile) -and (Test-Path $junitFile)) {
            try {
                $doc.Load($junitFile)
                $suites = $doc.DocumentElement
                if (-not $suites -or $suites.LocalName -ne 'testsuites') { $suites = $null; $doc = New-Object System.Xml.XmlDocument }
            }
            catch {
                Write-Host "WARNING: Could not load existing JUnit file '$junitFile' ($($_.Exception.Message)); starting fresh."
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
        $merged = @{}         # merged[codeunitId] = @{ method -> result }
        $totalElapsed = 0.0

        # PRIMARY execution: run each test codeunit in its OWN `al runtests <id> --testmethods`
        # invocation (a fresh session per codeunit). The official altool has no batch/plan mode,
        # so per-codeunit is the only supported execution model.
        foreach ($cu in $codeunits) {
            $cid = "$($cu.Id)"
            $methods = @($cu.Tests | ForEach-Object { "$_" })
            $run = Invoke-AlRunTestsForCodeunit -CodeunitId $cid -Methods $methods `
                -ProjectPath $projectPath -Company $company -Tenant $tenant -Connection $connection
            $totalElapsed += [double]$run.ElapsedSec
            if (-not $run.Connected) {
                Write-Host "::warning::al runtests did not complete for codeunit $cid ('$($cu.Name)') in app '$appName'. Raw output:"
                Write-Host $run.Raw
            }
            $merged[$cid] = $run.Results
        }

        # Rerun-on-failure pass. Each affected codeunit runs again in its OWN `al runtests` call
        # (a fresh session): a method that produced no result (a state-sensitive codeunit can leave
        # a method unreported) is retried for correctness, and a failed method is retried once to
        # recover flaky failures (mirroring BCH's rerun of failed tests).
        $isoGroups = @()
        foreach ($cu in $codeunits) {
            $cid = "$($cu.Id)"
            $requested = @($cu.Tests | ForEach-Object { "$_" })
            $cuResults = $merged[$cid]
            $retryMethods = @($requested | Where-Object {
                    $r = if ($cuResults) { $cuResults[$_] } else { $null }
                    ($null -eq $r) -or ($r.Outcome -eq 'Fail')
                })
            if ($retryMethods.Count -gt 0) {
                $isoGroups += @{ Id = $cid; Methods = $retryMethods; Name = $cu.Name }
            }
        }
        if ($isoGroups.Count -gt 0) {
            Write-Host ("rerun pass: {0} codeunit(s) with unreported or failed method(s) (each in its own session)" -f $isoGroups.Count)
            foreach ($g in $isoGroups) {
                $iso = Invoke-AlRunTestsForCodeunit -CodeunitId $g.Id -Methods $g.Methods `
                    -ProjectPath $projectPath -Company $company -Tenant $tenant -Connection $connection
                $totalElapsed += [double]$iso.ElapsedSec
                if (-not $merged.ContainsKey($g.Id)) { $merged[$g.Id] = @{} }
                foreach ($mName in $iso.Results.Keys) { $merged[$g.Id][$mName] = $iso.Results[$mName] }
            }
        }

        # Distribute the app's REAL al wall-clock across its codeunits weighted by each codeunit's
        # method-ms share (al's per-method `ms` under-reports real work, so it is used only for
        # weighting, not as the absolute suite time). Equal split as a fallback.
        $cuMsShare = @{}
        $grandMs = 0.0
        foreach ($cu in $codeunits) {
            $cuResults = $merged["$($cu.Id)"]
            $ms = 0.0
            if ($cuResults) { foreach ($mName in $cuResults.Keys) { $ms += [double]$cuResults[$mName].Ms } }
            $cuMsShare["$($cu.Id)"] = $ms
            $grandMs += $ms
        }

        # Build one JUnit <testsuite> per codeunit from the merged results.
        $idx = 0
        foreach ($cu in $codeunits) {
            $idx++
            $methods = @($cu.Tests | ForEach-Object { "$_" })
            $cuResults = $merged["$($cu.Id)"]
            if ($null -eq $cuResults) { $cuResults = @{} }

            if ($grandMs -gt 0) {
                $suiteSec = $totalElapsed * ($cuMsShare["$($cu.Id)"] / $grandMs)
            }
            elseif ($codeunits.Count -gt 0) {
                $suiteSec = $totalElapsed / $codeunits.Count
            }
            else {
                $suiteSec = 0.0
            }

            $failed = Add-JUnitTestSuite -Doc $doc -TestSuitesNode $suites -Codeunit $cu `
                -RequestedMethods $methods -MethodResults $cuResults -ExtensionId $extensionId `
                -AppName $appName -Hostname $hostname -ElapsedSec $suiteSec

            if ($failed -gt 0) { $allPassed = $false }

            Write-Host ("[{0}/{1}] cu {2} '{3}' -> {4} failed of {5} method(s)" -f `
                    $idx, $codeunits.Count, $cu.Id, $cu.Name, $failed, $methods.Count)
        }
        Write-Host ("Run for app '{0}': {1} codeunit(s) in {2}s real al wall-clock." -f `
                $appName, $codeunits.Count, [Math]::Round($totalElapsed, 2))

        if (-not [string]::IsNullOrWhiteSpace($junitFile)) {
            $dir = [System.IO.Path]::GetDirectoryName($junitFile)
            if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            $doc.Save($junitFile)
            Write-Host "Wrote JUnit results for app '$appName' to $junitFile"
        }
        else {
            Write-Host "WARNING: No JUnitResultFileName in parameters; results not persisted for app '$appName'."
        }

        return $allPassed
    }
    finally {
        # Do not let the container credential linger in the process environment after the run.
        Remove-Item Env:\BC_SERVER_USERNAME -ErrorAction SilentlyContinue
        Remove-Item Env:\BC_SERVER_PASSWORD -ErrorAction SilentlyContinue
    }
}

Export-ModuleMember -Function Install-AlTool, Get-AlToolConnection, New-AlToolProject, Get-AlToolCompany, `
    Get-DisabledTestKeySet, Get-AlToolTestCodeunits, ConvertFrom-AlRunTestsOutput, `
    Invoke-AlRunTestsForCodeunit, Add-JUnitTestSuite, Invoke-AlToolTestRun
