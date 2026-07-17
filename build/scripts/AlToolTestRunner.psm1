<#
.SYNOPSIS
    Experimental test runner that drives Microsoft's new `al runtests` (altool) CLI instead of
    BcContainerHelper's client-session runner, while producing the same JUnit XML the BCApps
    pipeline already consumes.

.DESCRIPTION
    This module is an exploratory replacement for the per-app execution inside
    build/scripts/RunTestsInBcContainer.ps1. Its goal is to measure how well the new headless
    `al runtests` runner works against a BCApps container, without changing AL-Go.

    For a single test app (identified by extensionId in the Run-AlPipeline parameters) it:
      1. Ensures the `al` CLI is installed (dotnet global tool, prerelease).
      2. Generates a throw-away AL project with a launch.json pointing at the container so
         `al runtests` has connection settings (explicit --server/--port flags are also passed).
      3. Enumerates the app's test codeunits + methods via Get-TestsFromBcContainer (honoring the
         same disabledTests and testType filtering the BCH runner would use).
      4. Runs `al runtests <codeunitId> --testmethods ...` once per codeunit against the
         container's default company, capturing per-method outcome, timing and failure message.
      5. Emits a JUnit results file matching the exact schema BcContainerHelper produces, so the
         downstream result-publishing and Test Tolerance steps keep working unchanged.

    Credentials are taken from the parameters' PSCredential and exposed to `al` through the
    BC_SERVER_USERNAME / BC_SERVER_PASSWORD environment variables (the only auth mechanism the CLI
    supports for on-prem UserPassword).

    Known altool output quirks handled here (see the evaluation handover):
      - The Results: block emits a phantom `PASS OnRun (..)` trigger entry and a trailing
        empty-named aggregate entry per codeunit; both are dropped so counts match the real methods.
      - Failure text is the indented lines after `FAIL <name> (Nms)` up to `AL Callstack:`; the
        callstack follows until the next result line.
#>

$ErrorActionPreference = "Stop"

$script:AlToolPackageId = "Microsoft.Dynamics.BusinessCentral.Development.Tools"

# Resolved once per process: the command used to invoke the al CLI. Defaults to the global tool ("al")
# but is overridden to a locally-built altool (build/altool-local/altool.exe) when present, so an
# experimental al build - e.g. one adding batched `--testplan` execution - can be dropped into the repo
# and exercised without publishing a NuGet package.
$script:AlExe = $null

<#
.SYNOPSIS
    Resolves the al executable to use: a repo-local build if present, otherwise the global `al` tool.
.OUTPUTS
    [string] Path to altool.exe, or "al".
#>
function Resolve-AlExe {
    if ($script:AlExe) { return $script:AlExe }

    # build/altool-local/altool.exe sits two levels up from this module (build/scripts/..).
    $localExe = Join-Path $PSScriptRoot "..\altool-local\altool.exe"
    if (Test-Path $localExe) {
        $script:AlExe = (Resolve-Path $localExe).Path
        Write-Host "Using repo-local altool build: $script:AlExe"
    } else {
        $script:AlExe = "al"
    }
    return $script:AlExe
}

<#
.SYNOPSIS
    Ensures the `al` CLI is available on PATH, installing/updating the prerelease dotnet global tool.
.OUTPUTS
    [string] The resolved `al` version string.
#>
function Install-AlTool {
    param(
        [switch]$Force
    )

    # When a repo-local altool build is present, use it directly and skip the global-tool install.
    $localExe = Join-Path $PSScriptRoot "..\altool-local\altool.exe"
    if (Test-Path $localExe) {
        $exe = Resolve-AlExe
        $version = (& $exe --version 2>&1 | Select-Object -First 1)
        Write-Host "Using al CLI version: $version (repo-local build)"
        return "$version"
    }

    $toolsPath = Join-Path $env:USERPROFILE ".dotnet\tools"
    if (($env:PATH -split ';') -notcontains $toolsPath) {
        $env:PATH = "$env:PATH;$toolsPath"
    }

    # The test harness dispatches one background job per app across tenants, all on the same runner
    # sharing one user profile. Concurrent `dotnet tool install --global` calls collide on the shared
    # tools store, so serialize install/update across processes with a named mutex and re-check
    # availability after acquiring it (another job may have just installed it).
    $mutex = New-Object System.Threading.Mutex($false, "Global\BCApps-AlTool-Install")
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
        } elseif ($Force) {
            # Explicit opt-in (e.g. the parent invocation) moves to the newest prerelease once, under
            # the mutex, so the per-app jobs afterwards simply find `al` and skip.
            try {
                & dotnet tool update $script:AlToolPackageId --global --prerelease *>&1 | ForEach-Object { Write-Host $_ }
            } catch {
                Write-Host "WARNING: 'al' update check failed ($($_.Exception.Message)). Using existing version."
            }
        }
    } finally {
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
.OUTPUTS
    [hashtable] @{ Server; ServerInstance; Port }
#>
function Get-AlToolConnection {
    param(
        [Parameter(Mandatory = $true)][string]$ContainerName
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
    } catch {
        Write-Host "WARNING: Could not read server configuration for '$ContainerName' ($($_.Exception.Message)). Falling back to $server/${instance}:$port."
    }

    return @{ Server = $server; ServerInstance = $instance; Port = $port }
}

<#
.SYNOPSIS
    Creates a throw-away AL project folder with a launch.json targeting the container so `al runtests`
    can resolve connection settings.
.OUTPUTS
    [string] Path to the generated project folder.
#>
function New-AlToolProject {
    param(
        [Parameter(Mandatory = $true)][string]$ContainerName,
        [Parameter(Mandatory = $true)][string]$Tenant,
        [Parameter(Mandatory = $true)][hashtable]$Connection
    )

    $projectRoot = Join-Path ([System.IO.Path]::GetTempPath()) "altool-project-$ContainerName"
    $vscodeDir = Join-Path $projectRoot ".vscode"
    New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null

    $appJson = [ordered]@{
        id        = [System.Guid]::NewGuid().ToString()
        name      = "AlToolTestDriver"
        publisher = "BCApps"
        version   = "1.0.0.0"
        platform  = "1.0.0.0"
        runtime   = "15.0"
    }
    $appJson | ConvertTo-Json | Set-Content -Path (Join-Path $projectRoot "app.json") -Encoding utf8

    $launch = [ordered]@{
        version        = "0.2.0"
        configurations = @(
            [ordered]@{
                name             = "altool"
                type             = "al"
                request          = "launch"
                server           = $Connection.Server
                serverInstance   = $Connection.ServerInstance
                port             = $Connection.Port
                tenant           = $Tenant
                authentication   = "UserPassword"
                environmentType  = "OnPrem"
                startupObjectId  = 22
                startupObjectType = "Page"
                schemaUpdateMode = "Synchronize"
            }
        )
    }
    $launch | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $vscodeDir "launch.json") -Encoding utf8

    return $projectRoot
}

<#
.SYNOPSIS
    Resolves the company `al runtests` should target. Defaults to the container's first company.
.OUTPUTS
    [string] Company name, or empty string if none could be resolved.
#>
function Get-AlToolCompany {
    param(
        [Parameter(Mandatory = $true)][string]$ContainerName,
        [Parameter(Mandatory = $true)][string]$Tenant
    )

    if ($env:ALTOOL_COMPANY) {
        return $env:ALTOOL_COMPANY
    }

    try {
        $companies = @(Get-CompanyInBcContainer -containerName $ContainerName -tenant $Tenant)
        if ($companies.Count -gt 0) {
            # Prefer an evaluation/default company when present, otherwise take the first.
            $preferred = $companies | Where-Object { $_.evaluationCompany -eq $true } | Select-Object -First 1
            $company = if ($preferred) { $preferred.companyName } else { $companies[0].companyName }
            return "$company"
        }
    } catch {
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
    the wildcard '*'. A '*' entry means the ENTIRE codeunit is disabled online (BCApps uses this to
    disable a whole codeunit), so it must exclude every method of that codeunit - not a literal method
    named '*'. Names/keys are lowercased for case-insensitive matching.
.OUTPUTS
    [hashtable] @{ Methods = <set of "<codeunitname>::<method>">; Codeunits = <set of "<codeunitname>"> }
#>
function Get-DisabledTestKeySet {
    param(
        [array]$DisabledTests = @()
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
                # Wildcard = whole codeunit disabled online.
                $codeunitSet[$cuName] = $true
            } else {
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
    Uses Get-TestsFromBcContainer with the app's extensionId and testType to list every test
    codeunit and method. BCH disables tests at RUN time via the test tool page's DisableTestMethod
    control, a mechanism `al runtests` bypasses entirely - so we must filter the disabled methods
    (and whole disabled codeunits, marked with a `*` wildcard) out of the enumerated list here,
    otherwise altool runs tests the pipeline treats as disabled.
.OUTPUTS
    [object[]] Codeunit objects with .Id, .Name, .Tests (enabled method name array).
#>
function Get-AlToolTestCodeunits {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Parameters
    )

    $getTestsParams = @{
        containerName = $Parameters.containerName
        tenant        = $Parameters.tenant
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

        # Whole codeunit disabled online (`*` wildcard) -> skip all its methods.
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
.OUTPUTS
    [hashtable] method name -> @{ Outcome (Pass/Fail/Skip); Ms; Message; Stacktrace }
#>
function ConvertFrom-AlRunTestsOutput {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][AllowEmptyString()][string[]]$OutputLines
    )

    $results = @{}
    $resultLineRegex = '^\s*(PASS|FAIL|SKIP)\s+(.*?)\s*\((\d+)ms\)\s*$'

    # Locate the Results: block; parse everything after it.
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

        # Drop phantom entries: OnRun trigger and the empty-named aggregate line.
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
                } else {
                    if ($next.Trim().Length -gt 0) { $msgLines += $next.Trim() }
                }
                $j++
            }
            $message = ($msgLines -join ' ').Trim()
            $stackText = ($stackLines -join ';')
            $i = $j
        } else {
            $i++
        }

        $results[$name] = @{ Outcome = $outcome; Ms = $ms; Message = $message; Stacktrace = $stackText }
    }

    return $results
}

<#
.SYNOPSIS
    Runs `al runtests` for one codeunit and returns the parsed per-method results plus raw output.
.OUTPUTS
    [hashtable] @{ Results (method->outcome map); ElapsedSec; Raw; Connected (bool) }
#>
function Invoke-AlRunTestsForCodeunit {
    param(
        [Parameter(Mandatory = $true)][string]$CodeunitId,
        [Parameter(Mandatory = $true)][string[]]$Methods,
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Company,
        [Parameter(Mandatory = $true)][string]$Tenant,
        [Parameter(Mandatory = $true)][hashtable]$Connection
    )

    # `al runtests` changed its DEFAULT output to structured JSON in 18.0.38; `--raw` restores the
    # human-readable text summary ("Test run completed: ..." + a "Results:" block of
    # "PASS|FAIL|SKIP <name> (Nms)" lines) that ConvertFrom-AlRunTestsOutput parses. Without it the
    # parser sees JSON, finds no result lines, and every method is reported as "No result produced".
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
    $output = & (Resolve-AlExe) @alArgs 2>&1
    $sw.Stop()

    $lines = @($output | ForEach-Object { "$_" })
    $connected = ($lines | Where-Object { $_ -match 'Test run completed:' }).Count -gt 0
    $parsed = ConvertFrom-AlRunTestsOutput -OutputLines $lines

    # Guard against silent output-format drift: if al reported a completed run but we parsed zero
    # method results, surface the raw output so the format change is diagnosable instead of every
    # method being silently marked "No result produced".
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
    Splits batched `al runtests --testplan --raw` output into per-codeunit result maps.
.DESCRIPTION
    The batched runner emits one block per codeunit, each preceded by a "===== Codeunit <id> ====="
    marker and containing a "Results:" section. This splits on the marker and parses each block with
    ConvertFrom-AlRunTestsOutput, keyed by codeunit id.
.OUTPUTS
    [hashtable] "<codeunitId>" -> (method-name -> @{ Outcome; Ms; Message; Stacktrace })
#>
function ConvertFrom-AlBatchOutput {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][AllowEmptyString()][string[]]$OutputLines
    )

    $byCodeunit = @{}
    $markerRegex = '^\s*=====\s*Codeunit\s+(\d+)\s*=====\s*$'

    $currentId = $null
    $currentLines = New-Object System.Collections.Generic.List[string]

    $flush = {
        if ($null -ne $currentId) {
            $byCodeunit["$currentId"] = ConvertFrom-AlRunTestsOutput -OutputLines @($currentLines.ToArray())
        }
    }

    foreach ($line in $OutputLines) {
        $m = [regex]::Match($line, $markerRegex)
        if ($m.Success) {
            & $flush
            $currentId = $m.Groups[1].Value
            $currentLines = New-Object System.Collections.Generic.List[string]
            continue
        }
        if ($null -ne $currentId) { $currentLines.Add($line) }
    }
    & $flush

    return $byCodeunit
}

<#
.SYNOPSIS
    Serializes a batch of test groups into the JSON array the al `--testplan` option expects.
.DESCRIPTION
    Built by hand (not ConvertTo-Json) because PowerShell's ConvertTo-Json collapses single-element
    arrays to a scalar/object - a one-codeunit plan would become {..} not [{..}], and a one-method
    list "M" not ["M"] - which the al tool rejects. This guarantees arrays at both levels for any count.
.PARAMETER Groups
    Array of @{ Id; Methods } describing the codeunits (and enabled methods) to run.
.OUTPUTS
    [string] JSON array: [{ "codeunitId": N, "testMethods": [ ... ] }, ...]
#>
function ConvertTo-AlTestPlanJson {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Groups
    )

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('[')
    $firstGroup = $true
    foreach ($g in $Groups) {
        if (-not $firstGroup) { [void]$sb.Append(',') }
        $firstGroup = $false
        $methodsJson = @($g.Methods | ForEach-Object { "$_" | ConvertTo-Json -Compress })
        [void]$sb.Append(('{{"codeunitId":{0},"testMethods":[{1}]}}' -f [int]$g.Id, ($methodsJson -join ',')))
    }
    [void]$sb.Append(']')
    return $sb.ToString()
}

<#
.SYNOPSIS
    Runs a batch of codeunits in ONE `al runtests --testplan` invocation (single connection + auth +
    session) and returns per-codeunit results. This is the batched analogue of
    Invoke-AlRunTestsForCodeunit and is what removes the per-codeunit connect/auth tax.
.PARAMETER Groups
    Array of @{ Id; Methods } describing the codeunits (and enabled methods) to run.
.OUTPUTS
    [hashtable] @{ Results ("<id>"->method map); ElapsedSec; Connected; Raw }
#>
function Invoke-AlBatchRunTests {
    param(
        [Parameter(Mandatory = $true)][object[]]$Groups,
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Company,
        [Parameter(Mandatory = $true)][string]$Tenant,
        [Parameter(Mandatory = $true)][hashtable]$Connection
    )

    # Write the test plan as a JSON file (avoids command-line length limits with many codeunits).
    $planFile = Join-Path ([System.IO.Path]::GetTempPath()) ("altool-plan-" + [System.Guid]::NewGuid().ToString('N') + ".json")
    Set-Content -Path $planFile -Value (ConvertTo-AlTestPlanJson -Groups $Groups) -Encoding utf8

    try {
        $alArgs = @(
            'runtests',
            '--testplan', $planFile,
            '--project', $ProjectPath,
            '--company', $Company,
            '--server', $Connection.Server,
            '--serverinstance', $Connection.ServerInstance,
            '--port', "$($Connection.Port)",
            '--environmenttype', 'OnPrem',
            '--authentication', 'UserPassword',
            '--tenant', $Tenant,
            '--raw'
        )

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $output = & (Resolve-AlExe) @alArgs 2>&1
        $sw.Stop()

        $lines = @($output | ForEach-Object { "$_" })
        $connected = ($lines | Where-Object { $_ -match 'Test run completed:' }).Count -gt 0
        $parsed = ConvertFrom-AlBatchOutput -OutputLines $lines

        if ($connected -and $parsed.Count -eq 0) {
            Write-Host "::warning::batched al runtests connected but produced no parseable per-codeunit results. Raw output follows:"
            Write-Host ($lines -join "`n")
        }

        return @{
            Results    = $parsed
            ElapsedSec = [Math]::Round($sw.Elapsed.TotalSeconds, 3)
            Raw        = ($lines -join "`n")
            Connected  = $connected
        }
    }
    finally {
        Remove-Item $planFile -Force -ErrorAction SilentlyContinue
    }
}

<#
.SYNOPSIS
    Appends a JUnit <testsuite> for one codeunit to the given <testsuites> document, matching the
    exact schema BcContainerHelper produces.
.OUTPUTS
    [int] Number of failing methods in this codeunit.
#>
function Add-JUnitTestSuite {
    param(
        [Parameter(Mandatory = $true)][System.Xml.XmlDocument]$Doc,
        [Parameter(Mandatory = $true)][System.Xml.XmlElement]$TestSuitesNode,
        [Parameter(Mandatory = $true)]$Codeunit,
        [Parameter(Mandatory = $true)][string[]]$RequestedMethods,
        [Parameter(Mandatory = $true)][hashtable]$MethodResults,
        [Parameter(Mandatory = $true)][string]$ExtensionId,
        [Parameter(Mandatory = $true)][string]$AppName,
        [Parameter(Mandatory = $true)][string]$Hostname,
        [Parameter(Mandatory = $true)][double]$ElapsedSec
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
        } else {
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
    Runs a codeunit and re-runs only the failed methods up to MaxAttempts, mirroring BCH's rerun pass.
.DESCRIPTION
    BCH's RunTestsInBcContainer reruns failed tests (maxAttempts=2 for non-Legacy, 1 for Legacy) and
    keeps the final outcome, which recovers flaky / transient failures. We replicate that per codeunit:
    run all methods, then re-run just the still-failing methods, overwriting each method's result with
    the latest attempt (a method that passes on any rerun ends up Pass). Elapsed time accumulates
    across attempts; Connected is true if any attempt connected.
.OUTPUTS
    [hashtable] @{ Results (method->outcome map); ElapsedSec; Connected; Attempts }
#>
function Invoke-AlRunTestsWithReruns {
    param(
        [Parameter(Mandatory = $true)][string]$CodeunitId,
        [Parameter(Mandatory = $true)][string[]]$Methods,
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Company,
        [Parameter(Mandatory = $true)][string]$Tenant,
        [Parameter(Mandatory = $true)][hashtable]$Connection,
        [int]$MaxAttempts = 1,
        [string]$CodeunitName = ""
    )

    $merged = @{}
    $totalElapsed = 0.0
    $anyConnected = $false
    $toRun = @($Methods)
    $attempt = 0

    while ($toRun.Count -gt 0 -and $attempt -lt $MaxAttempts) {
        $attempt++
        if ($attempt -gt 1) {
            Write-Host ("  rerun {0}/{1}: codeunit {2} '{3}' re-running {4} failed method(s)" -f `
                $attempt, $MaxAttempts, $CodeunitId, $CodeunitName, $toRun.Count)
        }

        $run = Invoke-AlRunTestsForCodeunit -CodeunitId $CodeunitId -Methods $toRun `
            -ProjectPath $ProjectPath -Company $Company -Tenant $Tenant -Connection $Connection

        $totalElapsed += $run.ElapsedSec
        if ($run.Connected) { $anyConnected = $true }

        # Overwrite each re-run method's result with this attempt's outcome (latest wins).
        foreach ($k in $run.Results.Keys) { $merged[$k] = $run.Results[$k] }

        # Determine which methods still need a rerun: failed, or produced no result this attempt.
        $toRun = @($toRun | Where-Object {
            $r = $merged[$_]
            ($null -eq $r) -or ($r.Outcome -eq 'Fail')
        })

        if (-not $run.Connected) { break } # a non-connecting attempt won't improve on rerun
    }

    return @{
        Results    = $merged
        ElapsedSec = [Math]::Round($totalElapsed, 3)
        Connected  = $anyConnected
        Attempts   = $attempt
    }
}

<#
.SYNOPSIS
    Runs all of a single app's test codeunits through `al runtests` and writes a JUnit results file.
.DESCRIPTION
    Replacement for the per-app BCH execution. Expects $Parameters to contain containerName, tenant,
    credential, extensionId, appName and (optionally) JUnitResultFileName. Returns whether every
    executed method passed.
.OUTPUTS
    [bool] $true if all methods passed and every codeunit connected; $false otherwise.
#>
function Invoke-AlToolTestRun {
    param(
        [Parameter(Mandatory = $true)][Hashtable]$Parameters,
        [string]$TestType = ""
    )

    Install-AlTool | Out-Null

    $containerName = $Parameters.containerName
    $tenant = if ($Parameters.tenant) { "$($Parameters.tenant)" } else { "default" }
    $extensionId = "$($Parameters.extensionId)"
    $appName = if ($Parameters.ContainsKey("appName")) { "$($Parameters.appName)" } else { "" }

    if ([string]::IsNullOrWhiteSpace($extensionId)) {
        throw "Invoke-AlToolTestRun requires 'extensionId' in parameters."
    }

    # Expose credentials to the al CLI (only auth channel it supports for on-prem UserPassword).
    if ($Parameters.credential -is [System.Management.Automation.PSCredential]) {
        $env:BC_SERVER_USERNAME = $Parameters.credential.UserName
        $env:BC_SERVER_PASSWORD = $Parameters.credential.GetNetworkCredential().Password
    } else {
        throw "Invoke-AlToolTestRun requires a PSCredential in parameters.credential."
    }

    $connection = Get-AlToolConnection -ContainerName $containerName
    $projectPath = New-AlToolProject -ContainerName $containerName -Tenant $tenant -Connection $connection
    $company = Get-AlToolCompany -ContainerName $containerName -Tenant $tenant
    if ([string]::IsNullOrWhiteSpace($company)) {
        throw "Could not resolve a company to run tests against in container '$containerName'."
    }

    Write-Host "altool run: app='$appName' extensionId=$extensionId testType='$TestType' company='$company' server='$($connection.Server)' instance='$($connection.ServerInstance)' port=$($connection.Port) tenant='$tenant'"

    $codeunits = @(Get-AlToolTestCodeunits -Parameters $Parameters)
    Write-Host "Enumerated $($codeunits.Count) test codeunit(s) for app '$appName'."
    if ($codeunits.Count -eq 0) {
        Write-Host "No test codeunits to run for app '$appName'; nothing to do."
        return $true
    }

    $hostname = [System.Net.Dns]::GetHostName()

    # The parallel harness (Start-TestJob) gives every app dispatched onto the SAME tenant the SAME
    # per-tenant JUnit file (name-<tenant>.xml). BCH's runner appends to that file across apps; if we
    # overwrite it, only the last app on each tenant survives (which is exactly the bug that left just
    # one app per tenant in the merged results). So load and append to the existing file when present.
    $junitFile = if ($Parameters.ContainsKey("JUnitResultFileName")) { $Parameters.JUnitResultFileName } else { "" }
    $doc = New-Object System.Xml.XmlDocument
    $suites = $null
    if (-not [string]::IsNullOrWhiteSpace($junitFile) -and (Test-Path $junitFile)) {
        try {
            $doc.Load($junitFile)
            $suites = $doc.DocumentElement
            if (-not $suites -or $suites.LocalName -ne 'testsuites') { $suites = $null; $doc = New-Object System.Xml.XmlDocument }
        } catch {
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

    if ($TestType -eq 'Legacy') {
        # Legacy is heavily state-dependent: running its codeunits in one shared batched session causes
        # widespread mid-batch "no result" casualties, and the isolated fallback then re-runs most of
        # the bucket one-by-one - which is SLOWER than just running isolated up front and blew past the
        # 6h job limit. Batching's win is on many-fast-codeunit unit suites, not Legacy, so run Legacy
        # per-codeunit in isolation (a fresh session each), mirroring the pre-batching behavior.
        Write-Host "TestType=Legacy: running $($codeunits.Count) codeunit(s) in isolation (batching disabled for Legacy)."
        $idx = 0
        foreach ($cu in $codeunits) {
            $idx++
            $methods = @($cu.Tests | ForEach-Object { "$_" })
            $run = Invoke-AlRunTestsWithReruns -CodeunitId "$($cu.Id)" -Methods $methods `
                -ProjectPath $projectPath -Company $company -Tenant $tenant -Connection $connection `
                -MaxAttempts 1 -CodeunitName "$($cu.Name)"
            $totalElapsed += [double]$run.ElapsedSec
            if (-not $run.Connected) {
                Write-Host "::warning::al runtests did not complete for codeunit $($cu.Id) '$($cu.Name)'."
                $allPassed = $false
            }
            $merged["$($cu.Id)"] = $run.Results
        }
    }
    else {
        # BATCHED execution: run every codeunit for this app in a SINGLE `al runtests --testplan`
        # invocation (one auth + one hub connection + one server Initialize). This removes the
        # per-codeunit connect/auth tax that dominates unit-test suites.
        $groups = @($codeunits | ForEach-Object { @{ Id = "$($_.Id)"; Methods = @($_.Tests | ForEach-Object { "$_" }) } })

        $batch = Invoke-AlBatchRunTests -Groups $groups -ProjectPath $projectPath -Company $company `
            -Tenant $tenant -Connection $connection
        if (-not $batch.Connected) {
            Write-Host "::warning::batched al runtests did not complete for app '$appName'. Raw output:"
            Write-Host $batch.Raw
            $allPassed = $false
        }
        foreach ($k in $batch.Results.Keys) { $merged[$k] = $batch.Results[$k] }
        $totalElapsed = [double]$batch.ElapsedSec

        # Isolated fallback + rerun pass. Each affected codeunit runs in its OWN `al runtests` call (a
        # fresh session), NOT another batch:
        #   1. No-result codeunits: batching runs everything in one shared session, so a state-sensitive
        #      codeunit (e.g. Language Test, which mutates the session language) can produce no results
        #      mid-batch. Re-running it in isolation restores the clean-session behavior it needs.
        #   2. Flaky failures: mirrors BCH's rerun of failed tests.
        # A method with no result is ALWAYS retried once (correctness); a Failed method is retried too
        # (non-Legacy path only reaches here). Bounded to a single isolated pass.
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
            Write-Host ("isolated fallback/rerun: {0} codeunit(s) (each in its own session)" -f $isoGroups.Count)
            foreach ($g in $isoGroups) {
                $iso = Invoke-AlRunTestsForCodeunit -CodeunitId $g.Id -Methods $g.Methods `
                    -ProjectPath $projectPath -Company $company -Tenant $tenant -Connection $connection
                $totalElapsed += [double]$iso.ElapsedSec
                if (-not $merged.ContainsKey($g.Id)) { $merged[$g.Id] = @{} }
                foreach ($mName in $iso.Results.Keys) { $merged[$g.Id][$mName] = $iso.Results[$mName] }
            }
        }
    }

    # Distribute the app's REAL al wall-clock ($totalElapsed) across its codeunits so the JUnit suite
    # times sum to the real execution time. NOTE: al's per-method `ms` drastically UNDER-reports real
    # work (it counts only AL code, not the server-side page/commit/setup time), so using the raw
    # method-ms sum as suite time makes the JUnit total look ~5x faster than reality. We therefore
    # weight the real total by each codeunit's method-ms share (equal split as a fallback).
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
        } elseif ($codeunits.Count -gt 0) {
            $suiteSec = $totalElapsed / $codeunits.Count
        } else {
            $suiteSec = 0.0
        }

        $failed = Add-JUnitTestSuite -Doc $doc -TestSuitesNode $suites -Codeunit $cu `
            -RequestedMethods $methods -MethodResults $cuResults -ExtensionId $extensionId `
            -AppName $appName -Hostname $hostname -ElapsedSec $suiteSec

        if ($failed -gt 0) { $allPassed = $false }

        Write-Host ("[{0}/{1}] cu {2} '{3}' -> {4} failed of {5} method(s)" -f `
            $idx, $codeunits.Count, $cu.Id, $cu.Name, $failed, $methods.Count)
    }
    Write-Host ("Run for app '{0}': {1} codeunit(s) in {2}s real al wall-clock (mode={3})." -f `
        $appName, $codeunits.Count, [Math]::Round($totalElapsed, 2), $(if ($TestType -eq 'Legacy') { 'isolated' } else { 'batched' }))

    if (-not [string]::IsNullOrWhiteSpace($junitFile)) {
        $dir = [System.IO.Path]::GetDirectoryName($junitFile)
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $doc.Save($junitFile)
        Write-Host "Wrote JUnit results for app '$appName' to $junitFile"
    } else {
        Write-Host "WARNING: No JUnitResultFileName in parameters; results not persisted for app '$appName'."
    }

    return $allPassed
}

Export-ModuleMember -Function Install-AlTool, Resolve-AlExe, Get-AlToolConnection, New-AlToolProject, Get-AlToolCompany, `
    Get-DisabledTestKeySet, Get-AlToolTestCodeunits, ConvertFrom-AlRunTestsOutput, ConvertFrom-AlBatchOutput, `
    ConvertTo-AlTestPlanJson, Invoke-AlRunTestsForCodeunit, Invoke-AlBatchRunTests, Invoke-AlRunTestsWithReruns, `
    Add-JUnitTestSuite, Invoke-AlToolTestRun
