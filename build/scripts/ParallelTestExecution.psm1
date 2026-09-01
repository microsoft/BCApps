Import-Module (Join-Path $PSScriptRoot "EnlistmentHelperFunctions.psm1" -Resolve)

# ALAppBuild.psm1 expects $env:INETROOT to point at the repo root and uses Write-Log
# internally. Set both up before importing so its functions work in CI runners that don't
# have the full NAV build environment configured.
if ([string]::IsNullOrEmpty($env:INETROOT)) {
    $env:INETROOT = Get-BaseFolder
}
if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    function global:Write-Log {
        param([Parameter(Position = 0)][string]$Message, [string]$ForegroundColor)
        Write-Host $Message
    }
}
Import-Module (Join-Path $PSScriptRoot "ALAppBuild.psm1" -Resolve)

<#
.SYNOPSIS
    Determines whether a disabled-test entry applies to the current country.
#>
function Test-DisabledTestAppliesToCountry {
    param(
        $DisabledTest,
        [string]$Country
    )

    if (-not $DisabledTest.PSObject.Properties['countries']) {
        return $true
    }

    return $Country -in @($DisabledTest.countries)
}

<#
.SYNOPSIS
    Gets disabled test entries for an app and filters country-scoped entries.
.PARAMETER AppName
    Application name used to locate its DisabledTests folder.
#>
function Get-DisabledTestsForApp {
    param(
        [Parameter(Mandatory=$true)]
        [string]$AppName
    )

    $appFolderName = $AppName -replace ' ', '_'
    $disabledTests = @()
    $country = Get-ALGoSetting -Key "country"

    $disabledTestsFolders = Get-ChildItem -Path (Get-BaseFolder) -Filter "DisabledTests" -Recurse -Directory
    foreach ($disabledTestsFolder in $disabledTestsFolders) {
        $appFolder = Join-Path $disabledTestsFolder.FullName $appFolderName
        if (-not (Test-Path $appFolder)) {
            continue
        }

        foreach ($jsonFile in (Get-ChildItem -Path $appFolder -Filter "*.json")) {
            $disabledTests += @(
                Get-Content -Raw -Path $jsonFile.FullName |
                    ConvertFrom-Json |
                    Where-Object { Test-DisabledTestAppliesToCountry -DisabledTest $_ -Country $country }
            )
        }
    }

    return @($disabledTests)
}

function Get-ParametersForCommand {
    param(
        [Parameter(Mandatory=$true)]
        [Hashtable]$Parameters,
        [Parameter(Mandatory=$true)]
        [string]$CommandName
    )

    $command = Get-Command $CommandName -ErrorAction Stop
    $filtered = @{}
    foreach ($key in $Parameters.Keys) {
        if ($command.Parameters.ContainsKey($key)) {
            $filtered[$key] = $Parameters[$key]
        }
    }
    return $filtered
}

function ConvertTo-RequiredDisabledWorkItems {
    param(
        [array]$DiscoveredTests,
        [string]$AppName,
        [string]$AppId
    )

    $codeunits = @()
    foreach ($entry in @($DiscoveredTests)) {
        if ($entry.PSObject.Properties.Name -contains "Codeunits") {
            $codeunits += @($entry.Codeunits)
        } else {
            $codeunits += $entry
        }
    }

    return @(
        $codeunits |
        Where-Object { $_ -and $_.Id -and @($_.Tests).Count -gt 0 } |
        ForEach-Object {
            [PSCustomObject]@{
                Key          = "${AppName}::$($_.Id)"
                AppName      = $AppName
                AppId        = $AppId
                CodeunitId   = [string]$_.Id
                CodeunitName = [string]$_.Name
                TestCount    = @($_.Tests).Count
            }
        }
    )
}

function Get-RequiredDisabledWorkItems {
    param(
        [Parameter(Mandatory=$true)]
        [Hashtable]$Parameters,
        [Parameter(Mandatory=$true)]
        [string]$TestType,
        [string[]]$AppNamesToTest,
        [Parameter(Mandatory=$true)]
        [Hashtable]$AppIdByName
    )

    $workItems = @()
    foreach ($appName in $AppNamesToTest) {
        $appId = $AppIdByName[$appName]
        if (-not $appId) {
            continue
        }

        $discoveryParameters = Get-ParametersForCommand -Parameters $Parameters -CommandName "Get-TestsFromBcContainer"
        $discoveryParameters["extensionId"] = $appId
        $discoveryParameters["requiredTestIsolation"] = "Disabled"
        $discoveryParameters["disabledTests"] = @(Get-DisabledTestsForApp -AppName $appName)
        if ($TestType -eq "Legacy") {
            $discoveryParameters.Remove("testType") | Out-Null
        } else {
            $discoveryParameters["testType"] = $TestType
        }

        Write-Host "Discovering RequiredTestIsolation=Disabled codeunits in '$appName'..."
        $discoveredTests = @(Get-TestsFromBcContainer @discoveryParameters)
        $appWorkItems = @(ConvertTo-RequiredDisabledWorkItems -DiscoveredTests $discoveredTests -AppName $appName -AppId $appId)
        if ($appWorkItems.Count -gt 0) {
            Write-Host "  Found $($appWorkItems.Count) codeunit(s), $((($appWorkItems | Measure-Object TestCount -Sum).Sum)) test method(s)."
            $workItems += $appWorkItems
        }
    }

    return @($workItems)
}

<#
.SYNOPSIS
    Returns the rerun budget for the current build.
.DESCRIPTION
    Reruns are a pull request convenience: they keep unrelated instability from blocking a review.
    CI/CD builds get a budget of 0 so a failure stays a failure. Those runs are the signal for the
    real state of the branch and they feed the unstable-tests data, so masking instability there
    would hide exactly what we want to measure. This mirrors the test tolerance check in
    RunTestsInBcContainer.ps1, which is also limited to pull request builds.

    On a pull request the budget comes from the "maxTestAppReruns" AL-Go setting. Because AL-Go
    merges repo, project and conditional settings before exposing them, the budget can be tuned per
    project or per build mode (for example a higher budget for the long legacy buckets) without any
    code change.

    The budget is the number of DIFFERENT apps that may be re-run in one job; an individual app is
    never re-run more than once (enforced separately via the rerun bookkeeping). A failed app is
    re-run on a DIFFERENT tenant than the one it failed on: tests are not guaranteed to clean up
    after themselves, so a same-tenant retry can re-fail on the residue the failed run just left
    behind. Keep it small - it exists to absorb instability, and more failures than this means
    something is genuinely broken rather than flaky.
.OUTPUTS
    [int] The configured budget on pull request builds, otherwise 0.
#>
function Get-AppRerunBudget {
    if ($env:GITHUB_EVENT_NAME -ne 'pull_request') {
        Write-Host "Build event is '$($env:GITHUB_EVENT_NAME)', not 'pull_request'. Failed test apps will NOT be re-run."
        return 0
    }

    $configured = Get-ALGoSetting -Key "maxTestAppReruns"
    if ($null -eq $configured) {
        Write-Host "AL-Go setting 'maxTestAppReruns' is not set. Failed test apps will NOT be re-run."
        return 0
    }

    $budget = $configured -as [int]
    Write-Host "Rerun budget for this job: $budget test app(s) may be re-run on a different tenant."
    return $budget
}

<#
.SYNOPSIS
    Returns the cached parallel-test-run result for a container, or $null if no run has finished.
.DESCRIPTION
    The first call into Invoke-ParallelTestExecution dispatches every test app in parallel,
    waits for completion, and persists the final result to a state file in $env:RUNNER_TEMP
    (cleaned up between jobs by GitHub Actions). Subsequent invocations from the per-project
    override should short-circuit using this helper to avoid redoing the work.
.OUTPUTS
    [bool] cached final result if dispatch completed; $null if no state file or not yet finished.
#>
function Get-CachedTestRunResult {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName
    )

    $tempDir = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { $env:TEMP }
    $stateFile = Join-Path $tempDir "parallelTests_$ContainerName.json"
    if (-not (Test-Path $stateFile)) { return $null }

    try {
        $state = Get-Content $stateFile -Raw | ConvertFrom-Json
        if ($state.completed) {
            return [bool]$state.finalResult
        }
    } catch {
        Write-Host "WARNING: Failed to parse state file '$stateFile' ($($_.Exception.Message))."
    }
    return $null
}

<#
.SYNOPSIS
    Resolves the authoritative app name for a project from its app.json "name" field.
.DESCRIPTION
    Get-ApplicationGroup exposes the projects.json key as ApplicationName. That key is required to
    match the app.json "name", but the two can drift (typos, "-Tests" vs " Test", trailing dots).
    When they drift, the container only ever knows the app.json "name", so any match keyed off
    ApplicationName silently drops the app from the test dispatch set and skips ALL of its tests
    while the build stays green. Reading the name straight from app.json (via AppJsonPath) makes
    the dispatch robust against that drift. Falls back to ApplicationName if app.json is missing
    or unreadable.
.OUTPUTS
    [string] The app.json "name", or ApplicationName as a fallback.
#>
function Get-AppNameFromMetadata {
    param(
        [Parameter(Mandatory=$true)]
        $BuildMetadata
    )

    $appJsonPath = $BuildMetadata.AppJsonPath
    if (-not [string]::IsNullOrWhiteSpace($appJsonPath) -and (Test-Path $appJsonPath -PathType Leaf)) {
        try {
            $appName = (Get-Content $appJsonPath -Raw | ConvertFrom-Json).name
            if (-not [string]::IsNullOrWhiteSpace($appName)) {
                if ($appName -ne $BuildMetadata.ApplicationName) {
                    Write-Host "::warning::Test app projects.json key '$($BuildMetadata.ApplicationName)' does not match its app.json name '$appName'. Using the app.json name for test dispatch. Align the projects.json key (and build/groups.json name) with the app.json name to avoid confusion."
                }
                return $appName
            }
        } catch {
            Write-Host "WARNING: Could not read app name from '$appJsonPath' ($($_.Exception.Message)); falling back to projects.json key '$($BuildMetadata.ApplicationName)'."
        }
    }
    return $BuildMetadata.ApplicationName
}

<#
.SYNOPSIS
    Returns the names of test apps that are both expected for a country and installed in the container.
.DESCRIPTION
    Combines the project metadata in build/projects.json (via Get-ApplicationGroup) with
    Get-BcContainerAppInfo so we only ever try to dispatch apps that actually exist in the
    container. The country defaults to "w1" when unset or set to the repo-level "base" sentinel.
    App names are resolved from each project's app.json "name" (via Get-AppNameFromMetadata) so a
    projects.json-key vs app.json-name mismatch cannot silently exclude a test app from dispatch.
#>
function Get-InstalledTestAppNames {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [string]$Tenant,
        [string]$Country
    )

    if ([string]::IsNullOrWhiteSpace($Country) -or $Country -eq "base") { $Country = "w1" }

    $allTestAppNames = @(
        Get-ApplicationGroup -GroupName "All" -CountryCode $Country -SkipLanguagePacks |
        Where-Object { $_.IsTest } |
        ForEach-Object { Get-AppNameFromMetadata -BuildMetadata $_ }
    )

    $installedAppNames = @(
        Get-BcContainerAppInfo -containerName $ContainerName -tenant $Tenant -tenantSpecificProperties |
        Where-Object { $_.IsInstalled } |
        Select-Object -ExpandProperty Name
    )

    return @($allTestAppNames | Where-Object { $_ -in $installedAppNames })
}

<#
.SYNOPSIS
    Filters and orders installed test apps according to the bucket configuration in TestConfiguration.json.
.DESCRIPTION
    For TestType=Legacy: returns apps in the named LegacyTests-Bucket{N}, ordered as listed.
    For non-Legacy: returns apps NOT in any LegacyTests-* bucket (order doesn't matter).
.OUTPUTS
    [string[]] Ordered list of app names to dispatch (possibly empty).
#>
function Get-AppNamesForBucket {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$InstalledTestAppNames,
        [Parameter(Mandatory=$true)]
        [string]$TestType,
        [int]$BucketNumber = 0
    )

    $testConfigPath = Join-Path (Get-BaseFolder) "build/scripts/TestConfiguration.json"
    if (-not (Test-Path $testConfigPath)) {
        return @($InstalledTestAppNames)
    }
    $testConfig = Get-Content $testConfigPath -Raw | ConvertFrom-Json

    if ($TestType -eq "Legacy") {
        $bucketOrder = @($testConfig."LegacyTests-Bucket$BucketNumber")
        return @($bucketOrder | Where-Object { $_ -in $InstalledTestAppNames })
    }

    $allLegacyTestApps = @()
    foreach ($prop in $testConfig.PSObject.Properties.Name) {
        if ($prop -like "LegacyTests-*") { $allLegacyTestApps += $testConfig.$prop }
    }
    return @($InstalledTestAppNames | Where-Object { $_ -notin $allLegacyTestApps })
}

function Get-CleanTenantTestAppNames {
    $testConfigPath = Join-Path (Get-BaseFolder) "build\scripts\TestConfiguration.json"
    if (-not (Test-Path $testConfigPath)) {
        return @()
    }

    $testConfig = Get-Content $testConfigPath -Raw | ConvertFrom-Json
    return @($testConfig.CleanTenantRequiredDisabled)
}

<#
.SYNOPSIS
    Gets the list of operational tenants in a BC container.
.PARAMETER containerName
    Name of the BC container to query.
.OUTPUTS
    [string[]] Array of tenant IDs that are in Operational state.
#>
function Get-AvailableBcTenantInfo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$containerName
    )

    $tenants = Invoke-ScriptInBcContainer -containerName $containerName -scriptblock {
        Get-NavTenant $ServerInstance |
            Where-Object { $_.State -eq "Operational" } |
            ForEach-Object {
                [PSCustomObject]@{
                    Id = $_.Id
                    DatabaseName = $_.DatabaseName
                }
            }
    }
    return @($tenants)
}

<#
.SYNOPSIS
    Gets the IDs of operational tenants in a BC container.
.PARAMETER containerName
    Name of the BC container.
#>
function Get-AvailableBcTenants {
    param(
        [Parameter(Mandatory=$true)]
        [string]$containerName
    )

    return @(
        Get-AvailableBcTenantInfo -containerName $containerName |
            ForEach-Object { $_.Id }
    )
}

function New-BcTestTenantTemplate {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [string]$SourceDatabaseName
    )

    $result = @(Invoke-ScriptInBcContainer -containerName $ContainerName -useSession $false -scriptblock { Param($sourceDatabaseName)
        $templateDatabaseName = "$sourceDatabaseName-test-template"
        $maxAttempts = 3
        $retryDelaySeconds = 5
        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            try {
                if (Test-NAVDatabase -DatabaseName $templateDatabaseName) {
                    Remove-NAVDatabase -DatabaseName $templateDatabaseName | Out-Null
                }

                Write-Host "Creating immutable test tenant template '$templateDatabaseName' from '$sourceDatabaseName' (attempt $attempt/$maxAttempts)..."
                Copy-NAVDatabase -SourceDatabaseName $sourceDatabaseName -DestinationDatabaseName $templateDatabaseName -DatabaseServer "." | Out-Null
                break
            } catch {
                Write-Host "WARNING: Template database copy failed on attempt $attempt/${maxAttempts}: $($_.Exception.Message)"
                if ($attempt -eq $maxAttempts) {
                    throw "Failed to create a test tenant template from '$sourceDatabaseName' after $maxAttempts attempts. Last error: $($_.Exception.Message)"
                }
                Start-Sleep -Seconds $retryDelaySeconds
            }
        }
        $templateDatabaseName
    } -argumentList $SourceDatabaseName)

    if ($result.Count -eq 0) {
        throw "Creating the clean test tenant template returned no database name."
    }
    return [string]$result[-1]
}

<#
.SYNOPSIS
    Replaces a tenant database with a copy of the immutable test template.
.PARAMETER ContainerName
    Name of the BC container.
.PARAMETER Tenant
    Tenant ID to refresh.
.PARAMETER TenantDatabaseName
    Database currently mounted for the tenant.
.PARAMETER TemplateDatabaseName
    Immutable source database copied before the next test codeunit.
#>
function Reset-BcTestTenant {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [string]$Tenant,
        [Parameter(Mandatory=$true)]
        [string]$TenantDatabaseName,
        [Parameter(Mandatory=$true)]
        [string]$TemplateDatabaseName
    )

    Invoke-ScriptInBcContainer -containerName $ContainerName -useSession $false -scriptblock {
        Param($tenant, $tenantDatabaseName, $templateDatabaseName)

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $mountedTenant = Get-NAVTenant -ServerInstance $ServerInstance -Tenant $tenant -ErrorAction SilentlyContinue
        if ($mountedTenant) {
            Dismount-NAVTenant -ServerInstance $ServerInstance -Tenant $tenant -Force | Out-Null
        }

        $maxAttempts = 3
        $retryDelaySeconds = 5
        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            try {
                if (Test-NAVDatabase -DatabaseName $tenantDatabaseName) {
                    Remove-NAVDatabase -DatabaseName $tenantDatabaseName | Out-Null
                }

                Copy-NAVDatabase -SourceDatabaseName $templateDatabaseName -DestinationDatabaseName $tenantDatabaseName -DatabaseServer "." | Out-Null
                break
            } catch {
                Write-Host "WARNING: Tenant database refresh failed on attempt $attempt/${maxAttempts}: $($_.Exception.Message)"
                if ($attempt -eq $maxAttempts) {
                    throw "Failed to refresh tenant database '$tenantDatabaseName' after $maxAttempts attempts. Last error: $($_.Exception.Message)"
                }
                Start-Sleep -Seconds $retryDelaySeconds
            }
        }
        Mount-NAVTenant -ServerInstance $ServerInstance -Id $tenant -DatabaseServer "." -DatabaseName $tenantDatabaseName -OverwriteTenantIdInDatabase -Force | Out-Null

        $maxWaitSeconds = 300
        while ((Get-NAVTenant -ServerInstance $ServerInstance -Tenant $tenant).State -eq "Mounting") {
            if ($stopwatch.Elapsed.TotalSeconds -ge $maxWaitSeconds) {
                throw "Tenant '$tenant' did not finish mounting within $maxWaitSeconds seconds."
            }
            Start-Sleep -Milliseconds 250
        }

        $state = (Get-NAVTenant -ServerInstance $ServerInstance -Tenant $tenant).State
        if ($state -notin @("Operational", "OperationalWithWarnings")) {
            throw "Tenant '$tenant' is '$state' after refresh; expected an operational state."
        }

        $stopwatch.Stop()
        Write-Host "Refreshed tenant '$tenant' from '$templateDatabaseName' in $([math]::Round($stopwatch.Elapsed.TotalSeconds, 2)) seconds."
    } -argumentList $Tenant, $TenantDatabaseName, $TemplateDatabaseName
}

function Remove-BcTestTenantTemplate {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [string]$TemplateDatabaseName
    )

    Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock { Param($templateDatabaseName)
        if (Test-NAVDatabase -DatabaseName $templateDatabaseName) {
            Remove-NAVDatabase -DatabaseName $templateDatabaseName | Out-Null
        }
    } -argumentList $TemplateDatabaseName
}

function Set-BcTestTaskScheduler {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [bool]$Enabled
    )

    Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock { Param($enabled)
        $state = if ($enabled) { "Enabling" } else { "Disabling" }
        $value = if ($enabled) { "true" } else { "false" }
        Write-Host "$state Task Scheduler for clean RequiredTestIsolation=Disabled execution..."
        Set-NAVServerConfiguration -ServerInstance $ServerInstance -KeyName "EnableTaskScheduler" -KeyValue $value -WarningAction SilentlyContinue
        Set-NAVServerInstance -ServerInstance $ServerInstance -Restart

        $maxWaitSeconds = 300
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        while (Get-NAVTenant $ServerInstance | Where-Object { $_.State -eq "Mounting" }) {
            if ($stopwatch.Elapsed.TotalSeconds -ge $maxWaitSeconds) {
                throw "Tenants did not finish mounting within $maxWaitSeconds seconds after changing Task Scheduler state."
            }
            Start-Sleep -Milliseconds 250
        }
    } -argumentList $Enabled
}

function Enable-BcTestTaskScheduler {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName
    )

    Set-BcTestTaskScheduler -ContainerName $ContainerName -Enabled $true
}

function Disable-BcTestTaskScheduler {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName
    )

    Set-BcTestTaskScheduler -ContainerName $ContainerName -Enabled $false
}

<#
.SYNOPSIS
    Merges multiple test result XML files into a single file.
.DESCRIPTION
    Supports both JUnit (<testsuites>/<testsuite>) and XUnit (<assemblies>/<assembly>) formats.
    Uses the first file as the base and appends test elements from remaining files. Entries are
    keyed by their "name" attribute (the codeunit) and later files win: an existing entry is
    removed before the new one is appended. That is what lets a rerun's results, merged last,
    replace the results of the run it re-ran.
.PARAMETER targetFile
    Path to the merged output file.
.PARAMETER sourceFiles
    Ordered array of result files to merge. Later files replace same-named entries from earlier ones.
#>
function Merge-TestResultFiles {
    param(
        [Parameter(Mandatory=$true)]
        [string]$targetFile,
        [Parameter(Mandatory=$true)]
        [string[]]$sourceFiles
    )

    $existingFiles = @($sourceFiles | Where-Object { Test-Path $_ })
    if ($existingFiles.Count -eq 0) {
        Write-Host "No test result files to merge"
        return
    }

    # Start with the first file as the base
    Copy-Item $existingFiles[0] $targetFile -Force
    Write-Host "Base result file: $($existingFiles[0])"

    if ($existingFiles.Count -eq 1) { return }

    # Merge remaining files into the base
    $baseXml = [xml](Get-Content $targetFile -Raw)

    foreach ($file in ($existingFiles | Select-Object -Skip 1)) {
        Write-Host "Merging results from: $file"
        $additionalXml = [xml](Get-Content $file -Raw)

        # JUnit format: root is <testsuites>, children are <testsuite>
        # XUnit format: root is <assemblies>, children are <assembly>
        $merged = $false
        foreach ($format in @(@{ Root = 'testsuites'; Child = 'testsuite' }, @{ Root = 'assemblies'; Child = 'assembly' })) {
            $nodes = $additionalXml.SelectNodes("//$($format.Root)/$($format.Child)")
            if (-not $nodes -or $nodes.Count -eq 0) { continue }

            $targetNode = $baseXml.SelectSingleNode("//$($format.Root)")
            foreach ($node in $nodes) {
                # Drop any earlier entry for the same codeunit so the later file wins. Compared on
                # the node itself rather than via XPath so names containing quotes are safe.
                $nodeName = $node.GetAttribute('name')
                @($targetNode.ChildNodes | Where-Object { $_.LocalName -eq $format.Child -and $_.GetAttribute('name') -eq $nodeName }) |
                    ForEach-Object { $targetNode.RemoveChild($_) | Out-Null }

                $imported = $baseXml.ImportNode($node, $true)
                $targetNode.AppendChild($imported) | Out-Null
            }
            $merged = $true
            break
        }

        if (-not $merged) {
            Write-Host "WARNING: Unrecognized test result format in $file, skipping"
        }
    }

    $baseXml.Save($targetFile)
    Write-Host "Merged $($existingFiles.Count) result files into $targetFile"
}

<#
.SYNOPSIS
    Returns $true if the output matches the known BC platform race signature.
.DESCRIPTION
    Race lives in InteractionManager.InvokeInteractions
    (Prod.ClientFwk\Interactions\InteractionManager.cs, around line 203 at time of writing).
    Any of these fingerprints is sufficient evidence: "Cannot open page 130455",
    "InvokeInteractions failed with status code 500", or a stack frame referencing
    "InteractionManager.cs:line N" (line number not pinned, so platform refactors do not
    silently invalidate the match). The platform can also fail while page 130455 resolves an
    extension's codeunit metadata; the known variants surface from ExtensionId_a45_OnValidate
    as an invalid metadata BLOB range or a missing nullable metadata value.
.PARAMETER Output
    The combined output (stdout + stderr + verbose) captured from a finished background
    job. Null or empty returns $false.
#>
function Test-TransientTestFailure {
    param(
        [string]$Output
    )

    if ([string]::IsNullOrEmpty($Output)) { return $false }
    return [bool](
        ($Output -match 'TRANSIENT TEST PLATFORM RACE') -or
        ($Output -match 'ClientSession State is InError') -or
        ($Output -match 'Cannot open page 130455|InvokeInteractions failed with status code 500|InteractionManager\.cs:line \d+') -or
        ($Output -match '(?s)ObjName:Command Line Test Tool.*MethodName:ExtensionId_a45_OnValidate.*(?:Offset and length were out of bounds|Nullable object must have a value)') -or
        ($Output -match '(?s)GET request failed\..*Response code is 500.*Object reference not set to an instance of an object')
    )
}

<#
.SYNOPSIS
    Receives a finished job's output, classifies the outcome, and removes the job.
.DESCRIPTION
    Outcome is 'Passed', 'Transient' (platform race + first failure), or 'Failed'. Output
    is captured into a StringBuilder inside the pipeline so it survives any terminating
    exception that Receive-Job rethrows from the background job.
.PARAMETER Entry
    Job descriptor from $state.jobs with .appName and .tenant.
.PARAMETER Job
    The PowerShell background job in a terminal state (Completed/Failed/Stopped).
.PARAMETER Retried
    Set of app names already retried once; matching apps that fail again classify as
    Failed instead of Transient, enforcing the one-retry cap. Membership is checked via
    ContainsKey; values are ignored.
.OUTPUTS
    [PSCustomObject] with Outcome, AppName, Tenant, JobState properties.
#>
function Receive-TestJobResult {
    param(
        $Entry,
        $Job,
        [Hashtable]$Retried
    )

    $sb = New-Object System.Text.StringBuilder
    try {
        Receive-Job -Job $Job *>&1 | ForEach-Object { Write-Host $_; [void]$sb.AppendLine("$_") }
    } catch {
        Write-Host "  (job emitted terminating error: $($_.Exception.Message))"
        # Capture the full ErrorRecord text (message + script stack trace + position info)
        # so the classifier can still match a transient signature that only appears outside
        # Exception.Message. Fall back to the bare message if Out-String yields nothing.
        $errText = ($_ | Out-String).TrimEnd()
        if ([string]::IsNullOrWhiteSpace($errText)) { $errText = $_.Exception.Message }
        [void]$sb.AppendLine($errText)
    }
    $output = $sb.ToString()

    $outcome = 'Passed'
    if ($Job.State -eq 'Failed' -or $Job.State -eq 'Stopped') {
        if ((Test-TransientTestFailure $output) -and -not $Retried.ContainsKey($Entry.appName)) {
            $outcome = 'Transient'
        } else {
            $outcome = 'Failed'
        }
    }

    Remove-Job -Job $Job -Force

    return [PSCustomObject]@{
        Outcome  = $outcome
        AppName  = $Entry.appName
        Tenant   = $Entry.tenant
        JobState = $Job.State
    }
}

<#
.SYNOPSIS
    Dispatches a single test app on a tenant and records the job. Sleeps 5s after to space
    consecutive OpenForm(130455) calls and avoid the platform race.
.PARAMETER Parameters
    The Run-AlPipeline parameters hashtable. Cloned per dispatch and mutated with
    appName/extensionId.
.PARAMETER AppName
    The test app name (e.g. 'Tests-SCM-Service'); used for logging and result file naming.
.PARAMETER AppId
    The app's extensionId GUID; selects which app's tests Run-TestsInBcContainer runs.
.PARAMETER Tenant
    The tenant id to dispatch onto.
.PARAMETER ScriptPath
    Path to the RunTestsInBcContainer.ps1 script invoked by the background job.
.PARAMETER TestType
    The test type (Legacy, UnitTest, etc.) forwarded to the background job.
.PARAMETER State
    The parallel execution state object; the new job descriptor is appended to State.jobs.
.PARAMETER Verb
    Log verb, 'Dispatching' for the initial run or 'Re-dispatching' for a retry.
.PARAMETER FileSuffix
    Suffix for the per-job result file. Defaults to the tenant id; a rerun passes its own suffix so
    its results land in a separate file that replaces the failed run's during the merge.
#>
function Start-TestAppDispatch {
    param(
        [Hashtable]$Parameters,
        [string]$AppName,
        [string]$AppId,
        [string]$Tenant,
        [string]$ScriptPath,
        [string]$TestType,
        $State,
        [switch]$SkipAutomaticDisabledPass,
        [string]$Verb = 'Dispatching',
        [string]$FileSuffix
    )

    Write-Host "$Verb '$AppName' (extensionId $AppId) on tenant '$Tenant' in background"

    $appParams = $Parameters.Clone()
    $appParams['appName'] = $AppName
    $appParams['extensionId'] = $AppId
    $appParams.Remove('ReRun') | Out-Null

    $job = Start-TestJob -parameters $appParams -tenant $Tenant -scriptPath $ScriptPath -testType $TestType `
        -skipAutomaticDisabledPass:$SkipAutomaticDisabledPass -fileSuffix $FileSuffix
    $State.jobs = @($State.jobs) + @([PSCustomObject]@{ jobId = $job.Id; tenant = $Tenant; appName = $AppName })

    Start-Sleep -Seconds 5
}

function Start-RequiredDisabledDispatch {
    param(
        [Hashtable]$Parameters,
        $WorkItem,
        $TenantInfo,
        [string]$ScriptPath,
        [string]$TestType,
        $State,
        [string]$Verb = "Dispatching"
    )

    Write-Host "$Verb RequiredTestIsolation=Disabled codeunit $($WorkItem.CodeunitId) '$($WorkItem.CodeunitName)' from '$($WorkItem.AppName)' on tenant '$($TenantInfo.Id)'"

    $codeunitParameters = $Parameters.Clone()
    $codeunitParameters["appName"] = $WorkItem.AppName
    $codeunitParameters["extensionId"] = $WorkItem.AppId
    $codeunitParameters["testCodeunit"] = $WorkItem.CodeunitId
    $codeunitParameters["requiredTestIsolation"] = "Disabled"
    $codeunitParameters["testRunnerCodeunitId"] = "130451"
    $codeunitParameters["disabledTests"] = @(Get-DisabledTestsForApp -AppName $WorkItem.AppName)
    $codeunitParameters.Remove("ReRun") | Out-Null
    if ($Verb -eq "Re-dispatching") {
        $codeunitParameters["ReRun"] = $true
    }

    $appendKeys = @{
        XUnitResultFileName = "AppendToXUnitResultFile"
        JUnitResultFileName = "AppendToJUnitResultFile"
    }
    foreach ($resultKey in $appendKeys.Keys) {
        if ($codeunitParameters.ContainsKey($resultKey) -and $codeunitParameters[$resultKey]) {
            $codeunitParameters[$appendKeys[$resultKey]] = $true
        }
    }

    $job = Start-TestJob -parameters $codeunitParameters -tenant $TenantInfo.Id -scriptPath $ScriptPath `
        -testType $TestType -skipAutomaticDisabledPass
    $State.jobs = @($State.jobs) + @(
        [PSCustomObject]@{
            jobId = $job.Id
            tenant = $TenantInfo.Id
            appName = $WorkItem.Key
        }
    )
    Start-Sleep -Seconds 1
}

function Invoke-RequiredDisabledTestExecution {
    param(
        [Parameter(Mandatory=$true)]
        [Hashtable]$Parameters,
        [Parameter(Mandatory=$true)]
        [array]$WorkItems,
        [Parameter(Mandatory=$true)]
        [array]$TenantInfo,
        [Parameter(Mandatory=$true)]
        [string]$TemplateDatabaseName,
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,
        [Parameter(Mandatory=$true)]
        [string]$TestType
    )

    if ($WorkItems.Count -eq 0) {
        return $true
    }

    $workItemByKey = @{}
    foreach ($workItem in $WorkItems) {
        $workItemByKey[$workItem.Key] = $workItem
    }

    $state = [PSCustomObject]@{
        jobs = @()
        hasFailures = $false
        transient = @()
        retried = @{}
        retryTenant = @{}
    }
    $pending = @($WorkItems)

    while ($pending.Count -gt 0 -or $state.transient.Count -gt 0) {
        if ($state.transient.Count -gt 0) {
            $retryItems = @()
            foreach ($transient in @($state.transient)) {
                $key = $transient.Key
                $state.retried[$key] = $true
                $state.retryTenant[$key] = $transient.Tenant
                $retryItems += $workItemByKey[$key]
            }
            $state.transient = @()
            $pending = @($retryItems) + @($pending)
        }

        $availableTenantInfo = @($TenantInfo)
        $batch = @()
        while ($pending.Count -gt 0 -and $availableTenantInfo.Count -gt 0) {
            $workItem = $pending[0]
            $pending = @($pending | Select-Object -Skip 1)
            $selectedTenantInfo = if ($state.retryTenant.ContainsKey($workItem.Key)) {
                $availableTenantInfo |
                    Where-Object { $_.Id -eq $state.retryTenant[$workItem.Key] } |
                    Select-Object -First 1
            } else {
                $availableTenantInfo | Select-Object -First 1
            }
            if (-not $selectedTenantInfo) {
                throw "Could not reserve tenant for clean codeunit '$($workItem.Key)'."
            }
            $availableTenantInfo = @($availableTenantInfo | Where-Object { $_.Id -ne $selectedTenantInfo.Id })
            $verb = if ($state.retried.ContainsKey($workItem.Key)) { "Re-dispatching" } else { "Dispatching" }

            $batch += [PSCustomObject]@{
                WorkItem = $workItem
                TenantInfo = $selectedTenantInfo
                Verb = $verb
            }
        }

        # Finish every restore in the batch before any test starts. This keeps SQL backup/restore
        # activity from overlapping page 130455 metadata enumeration and API cold starts.
        foreach ($dispatch in $batch) {
            Reset-BcTestTenant -ContainerName $Parameters.containerName -Tenant $dispatch.TenantInfo.Id `
                -TenantDatabaseName $dispatch.TenantInfo.DatabaseName -TemplateDatabaseName $TemplateDatabaseName
        }
        foreach ($dispatch in $batch) {
            Start-RequiredDisabledDispatch -Parameters $Parameters -WorkItem $dispatch.WorkItem `
                -TenantInfo $dispatch.TenantInfo `
                -ScriptPath $ScriptPath -TestType $TestType -State $state -Verb $dispatch.Verb
        }
        $null = Wait-ForAllTestJobs -state $state
    }

    return (-not $state.hasFailures)
}

<#
.SYNOPSIS
    Records a finished job's outcome on the state object, queueing a rerun when one is warranted.
.DESCRIPTION
    'Transient' feeds the existing platform-race retry queue. 'Failed' consumes one unit of the
    global rerun budget and queues the app to run again on a different tenant; when the budget is
    exhausted (or the app has already been re-run, or there is only one tenant so a different one
    cannot be guaranteed) the failure is final and sets hasFailures.
.PARAMETER Result
    The outcome object returned by Receive-TestJobResult.
.PARAMETER State
    The parallel execution state object; mutated in place.
#>
function Register-TestJobOutcome {
    param(
        $Result,
        $State
    )

    switch ($Result.Outcome) {
        'Transient' {
            Write-Host "Transient platform race for '$($Result.AppName)' on '$($Result.Tenant)'. Queued for one retry."
            $State.transient = @($State.transient) + @(
                [PSCustomObject]@{
                    Key = $Result.AppName
                    Tenant = $Result.Tenant
                }
            )
        }
        'Failed' {
            $supportsAppReruns = $null -ne $State.PSObject.Properties['rerunBudget']
            $canRerun = $supportsAppReruns -and
                        ($State.rerunBudget -gt 0) -and
                        ($State.tenantCount -gt 1) -and
                        (-not $State.rerunDone.ContainsKey($Result.AppName))

            if ($canRerun) {
                $State.rerunBudget = $State.rerunBudget - 1
                # Suffix is derived from the number of reruns so far, so it stays unique and
                # correct regardless of what the starting budget was. Keep it in rerunDone: if the
                # rerun itself later hits a transient platform race, the loop needs the suffix to
                # discard the stale rerun result file before re-dispatching.
                $suffix = "rerun$($State.rerunDone.Count + 1)"
                $State.rerunDone[$Result.AppName] = $suffix
                Write-Host "::warning::Tests FAILED for '$($Result.AppName)' on tenant '$($Result.Tenant)'. Re-running the app once on a different tenant. A rerun that passes still means this app is unstable - please investigate it."
                $State.rerun = @($State.rerun) + @([PSCustomObject]@{
                    appName       = $Result.AppName
                    excludeTenant = $Result.Tenant
                    suffix        = $suffix
                })
            }
            else {
                Write-Host "Tests FAILED for $($Result.AppName) on $($Result.Tenant) (job state: $($Result.JobState))"
                $State.hasFailures = $true
            }
        }
    }
}

<#
.SYNOPSIS
    Collects finished jobs and returns tenants that are not currently busy.
.PARAMETER state
    The parallel execution state object containing the jobs array.
.PARAMETER tenants
    Array of all tenant IDs to check availability for.
.OUTPUTS
    [string[]] Array of tenant IDs that are not running a test job.
#>
function Get-FreeTenants {
    param($state, $tenants)

    $terminalStates = @("Completed", "Failed", "Stopped")

    $busyTenants = @()
    $remainingJobs = @()
    foreach ($entry in $state.jobs) {
        $job = Get-Job -Id $entry.jobId -ErrorAction SilentlyContinue
        if (-not $job) {
            continue
        }
        if ($job.State -notin $terminalStates) {
            # Still running, queued (NotStarted), or paused (Blocked/Suspended) — keep it
            $busyTenants += $entry.tenant
            $remainingJobs += $entry
        } else {
            $result = Receive-TestJobResult -Entry $entry -Job $job -Retried $state.retried
            Register-TestJobOutcome -Result $result -State $state
        }
    }
    $state.jobs = @($remainingJobs)

    return @($tenants | Where-Object { $_ -notin $busyTenants })
}

<#
.SYNOPSIS
    Waits until at least one tenant is free, then returns its ID.
.PARAMETER state
    The parallel execution state object.
.PARAMETER tenants
    Array of all tenant IDs.
.PARAMETER excludeTenant
    Tenant to never return. Used to keep a rerun off the tenant its previous run failed on.
.OUTPUTS
    [string] The first available tenant ID.
#>
function Wait-ForFreeTenant {
    param(
        $state,
        $tenants,
        [string]$excludeTenant,
        [int]$timeoutSeconds = 7200,
        [int]$pollIntervalSeconds = 10
    )

    $waited = 0
    while ($waited -lt $timeoutSeconds) {
        $available = @(Get-FreeTenants -state $state -tenants $tenants | Where-Object { $_ -ne $excludeTenant })
        if ($available) {
            return $available[0]
        }
        Start-Sleep -Seconds $pollIntervalSeconds
        $waited += $pollIntervalSeconds
    }

    throw "Wait-ForFreeTenant: timed out after $timeoutSeconds seconds waiting for a free tenant. Running jobs: $($state.jobs | ForEach-Object { "$($_.appName) on $($_.tenant)" } | Out-String)"
}

function Wait-ForSpecificTenant {
    param(
        $state,
        $tenants,
        [string]$tenant,
        [int]$timeoutSeconds = 7200,
        [int]$pollIntervalSeconds = 10
    )

    $waited = 0
    while ($waited -lt $timeoutSeconds) {
        $available = @(Get-FreeTenants -state $state -tenants $tenants)
        if ($tenant -in $available) {
            return $tenant
        }
        Start-Sleep -Seconds $pollIntervalSeconds
        $waited += $pollIntervalSeconds
    }

    throw "Wait-ForSpecificTenant: timed out after $timeoutSeconds seconds waiting for tenant '$tenant'."
}

<#
.SYNOPSIS
    Starts a background job to run tests for a single app on a specific tenant.
.PARAMETER parameters
    The original test parameters hashtable from Run-AlPipeline.
.PARAMETER tenant
    The tenant ID to run tests on.
.PARAMETER scriptPath
    Path to RunTestsInBcContainer.ps1.
.PARAMETER testType
    The test type (Legacy, UnitTest, etc.)
.PARAMETER fileSuffix
    Suffix used for this job's result file. Defaults to the tenant id.
.OUTPUTS
    [System.Management.Automation.Job] The background job object.
#>
function Start-TestJob {
    param(
        [Hashtable]$parameters,
        [string]$tenant,
        [string]$scriptPath,
        [string]$testType,
        [switch]$skipAutomaticDisabledPass,
        [string]$fileSuffix
    )

    $jobParams = $parameters.Clone()
    $jobParams["tenant"] = $tenant

    if ([string]::IsNullOrWhiteSpace($fileSuffix)) { $fileSuffix = $tenant }

    # Give each job its own result file to avoid write conflicts
    foreach ($resultKey in @("XUnitResultFileName", "JUnitResultFileName")) {
        if ($jobParams.ContainsKey($resultKey) -and $jobParams[$resultKey]) {
            $origFile = $jobParams[$resultKey]
            $dir = [System.IO.Path]::GetDirectoryName($origFile)
            $name = [System.IO.Path]::GetFileNameWithoutExtension($origFile)
            $ext = [System.IO.Path]::GetExtension($origFile)
            $jobParams[$resultKey] = Join-Path $dir "$name-$fileSuffix$ext"
        }
    }

    # Resolve BCH module path from the currently loaded module
    $bchModule = Get-Module BcContainerHelper | Select-Object -First 1
    $bchModulePath = if ($bchModule) { $bchModule.Path } else { "BcContainerHelper" }

    $jobScript = {
        param($params, $scriptPath, $testType, $bchPath, $skipDisabledPass)
        Import-Module $bchPath
        # Background jobs run a single app sequentially. Pass an empty $AppNamesToTest so the
        # shared script skips the parallel dispatch branch and falls through to running this
        # one app's tests directly.
        $passed = . $scriptPath -parameters $params -TestType $testType -AppNamesToTest @() `
            -SkipAutomaticDisabledPass:$skipDisabledPass
        if (-not $passed) { throw "Test execution failed" }
    }

    return Start-Job -ScriptBlock $jobScript -ArgumentList $jobParams, $scriptPath, $testType, $bchModulePath, `
        $skipAutomaticDisabledPass.IsPresent
}

<#
.SYNOPSIS
    Waits for all tracked test jobs to complete, recording each outcome on the state object.
.DESCRIPTION
    Outcomes are recorded on $state by Register-TestJobOutcome (hasFailures / transient / rerun),
    which is the single source of truth for the run result. Deliberately returns nothing: a
    "did everything pass" boolean cannot be derived here, because $state.hasFailures may already
    be true from an earlier batch and would mask a new failure in this one.
.PARAMETER state
    The parallel execution state object containing the jobs array.
#>
function Wait-ForAllTestJobs {
    param($state)

    foreach ($entry in @($state.jobs)) {
        $pendingJob = Get-Job -Id $entry.jobId -ErrorAction SilentlyContinue
        if ($pendingJob) {
            Write-Host "Waiting for '$($entry.appName)' on '$($entry.tenant)'..."
            Wait-Job -Job $pendingJob | Out-Null

            $result = Receive-TestJobResult -Entry $entry -Job $pendingJob -Retried $state.retried
            Register-TestJobOutcome -Result $result -State $state
        }
    }
    # All jobs in $state.jobs have been received and removed; clear the list so any later
    # dispatch starts from a clean slate (otherwise stale descriptors confuse Get-FreeTenants).
    $state.jobs = @()
}

function Add-MissingJUnitTestProperties {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ResultFile,
        [array]$WorkItems = @()
    )

    if (-not (Test-Path $ResultFile) -or $WorkItems.Count -eq 0) {
        return
    }

    $workItemByCodeunitId = @{}
    foreach ($workItem in $WorkItems) {
        $workItemByCodeunitId[[string]$workItem.CodeunitId] = $workItem
    }

    $xml = [xml](Get-Content $ResultFile -Raw)
    $changed = $false
    foreach ($suite in @($xml.testsuites.testsuite)) {
        if ($suite.properties) {
            continue
        }

        $codeunitId = ([string]$suite.name -split ' ', 2)[0]
        $workItem = $workItemByCodeunitId[$codeunitId]
        if (-not $workItem) {
            continue
        }

        $properties = $xml.CreateElement("properties")
        foreach ($propertyValue in @{
            extensionid = $workItem.AppId
            appName = $workItem.AppName
        }.GetEnumerator()) {
            $property = $xml.CreateElement("property")
            $property.SetAttribute("name", $propertyValue.Key)
            $property.SetAttribute("value", [string]$propertyValue.Value)
            $properties.AppendChild($property) | Out-Null
        }

        if ($suite.FirstChild) {
            $suite.InsertBefore($properties, $suite.FirstChild) | Out-Null
        } else {
            $suite.AppendChild($properties) | Out-Null
        }
        $changed = $true
    }

    if ($changed) {
        $xml.Save($ResultFile)
    }
}

<#
.SYNOPSIS
    Merges per-job test result files into the single file expected by Run-AlPipeline.
.PARAMETER parameters
    The original test parameters hashtable (contains the expected result file paths).
.PARAMETER tenants
    Array of tenant IDs whose result files should be merged.
.PARAMETER rerunSuffixes
    Suffixes of any rerun result files. Merged after the tenant files so a rerun's results replace
    those of the failed run it re-ran.
#>
function Merge-TenantTestResults {
    param(
        [Hashtable]$parameters,
        [string[]]$tenants,
        [array]$workItems = @(),
        [string[]]$rerunSuffixes = @()
    )

    $suffixes = @($tenants) + @($rerunSuffixes)

    foreach ($resultKey in @("XUnitResultFileName", "JUnitResultFileName")) {
        if ($parameters.ContainsKey($resultKey) -and $parameters[$resultKey]) {
            $origFile = $parameters[$resultKey]
            $dir = [System.IO.Path]::GetDirectoryName($origFile)
            $name = [System.IO.Path]::GetFileNameWithoutExtension($origFile)
            $ext = [System.IO.Path]::GetExtension($origFile)

            $tenantFiles = @($suffixes | ForEach-Object { Join-Path $dir "$name-$_$ext" })
            if ($resultKey -eq "JUnitResultFileName") {
                foreach ($tenantFile in $tenantFiles) {
                    Add-MissingJUnitTestProperties -ResultFile $tenantFile -WorkItems $workItems
                }
            }
            Merge-TestResultFiles -targetFile $origFile -sourceFiles $tenantFiles

            # Clean up per-job files
            $tenantFiles | Where-Object { Test-Path $_ } | ForEach-Object { Remove-Item $_ -Force }
        }
    }
}

<#
.SYNOPSIS
    Runs the first test app alone and awaits it before the parallel fan-out. Returns the remaining
    apps still to dispatch.
.DESCRIPTION
    Concurrent per-tenant company-opens can race on the first use of the container's process-wide
    GDI+ state, so the first open is serialized: one app runs alone and is awaited to completion,
    then the caller fans out the rest. Warms once per container - no-op for a single app or tenant.
    A transient failure on the warmed-up app flows into $State.transient and is re-queued normally.
.PARAMETER Pending
    The ordered list of app names still to dispatch. The first app is consumed for the warmup.
.PARAMETER AppIdByName
    Map of app name -> extensionId. If the first app's id cannot be resolved, warmup is skipped.
.PARAMETER Tenants
    All available tenant ids. Warmup dispatches onto the first one.
.PARAMETER State
    The parallel execution state object; mutated (jobs/hasFailures/transient) as the warmup runs.
.PARAMETER CleanTenantAppNames
    Apps whose automatic Disabled-isolation pass must be deferred to clean-codeunit execution.
.OUTPUTS
    [string[]] The remaining app names to dispatch (first app removed if it was warmed up).
#>
function Invoke-WarmupDispatch {
    param(
        [Parameter(Mandatory=$true)][Hashtable]$Parameters,
        [Parameter(Mandatory=$true)][AllowEmptyCollection()][string[]]$Pending,
        [Parameter(Mandatory=$true)][Hashtable]$AppIdByName,
        [Parameter(Mandatory=$true)][AllowEmptyCollection()][string[]]$Tenants,
        [Parameter(Mandatory=$true)][string]$ScriptPath,
        [string]$TestType,
        [Parameter(Mandatory=$true)]$State,
        [string[]]$CleanTenantAppNames = @()
    )

    # Only serialize when there is a fan-out to protect: >1 app AND >1 tenant.
    if ($Pending.Count -le 1 -or $Tenants.Count -le 1) {
        return @($Pending)
    }

    $warmupApp = $Pending[0]
    $warmupAppId = $AppIdByName[$warmupApp]
    if (-not $warmupAppId) {
        # Leave the app in the queue so the main loop emits its usual appId warning.
        return @($Pending)
    }

    Write-Host "Warming up: dispatching first app '$warmupApp' on '$($Tenants[0])' alone and awaiting completion before parallel fan-out."
    Start-TestAppDispatch -Parameters $Parameters -AppName $warmupApp -AppId $warmupAppId -Tenant $Tenants[0] `
        -ScriptPath $ScriptPath -TestType $TestType -State $State -Verb 'Dispatching' `
        -SkipAutomaticDisabledPass:($warmupApp -in $CleanTenantAppNames)

    # Await the single job so the process is warm before anything runs in parallel. A transient
    # failure here lands in $State.transient and the caller's loop re-queues it; a hard failure is
    # recorded on $State by Wait-ForAllTestJobs.
    $null = Wait-ForAllTestJobs -state $State

    return @($Pending | Select-Object -Skip 1)
}

<#
.SYNOPSIS
    Deletes the result file written by a rerun, so it cannot take part in the merge.
.DESCRIPTION
    Merge-TenantTestResults merges tenant files first and rerun files last, so a rerun result
    always wins for the app it re-ran. That is correct while the rerun is the app's final attempt.
    If the rerun instead hits a transient platform race, the app is re-dispatched through the
    normal queue and writes to a TENANT file - and the stale rerun file would then overwrite the
    newer result, reporting a passing app as failed. Removing the stale file keeps the merge honest.
.PARAMETER parameters
    The original test parameters hashtable (contains the expected result file paths).
.PARAMETER suffix
    The rerun suffix whose files should be removed (for example 'rerun1').
#>
function Remove-RerunResultFile {
    param(
        [Hashtable]$parameters,
        [string]$suffix
    )

    if ([string]::IsNullOrWhiteSpace($suffix)) { return }

    foreach ($resultKey in @("XUnitResultFileName", "JUnitResultFileName")) {
        if ($parameters.ContainsKey($resultKey) -and $parameters[$resultKey]) {
            $origFile = $parameters[$resultKey]
            $dir = [System.IO.Path]::GetDirectoryName($origFile)
            $name = [System.IO.Path]::GetFileNameWithoutExtension($origFile)
            $ext = [System.IO.Path]::GetExtension($origFile)
            $staleFile = Join-Path $dir "$name-$suffix$ext"

            if (Test-Path $staleFile) {
                Write-Host "Discarding stale rerun result file '$staleFile'; the app is being re-dispatched after a transient failure."
                Remove-Item $staleFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

<#
.SYNOPSIS
    Dispatches test apps in parallel across all available tenants in a BC container.
.DESCRIPTION
    Walks $appNamesToTest in order, dispatching each app onto a free tenant via background jobs.
    Waits for all jobs to complete, merges per-tenant result files, and returns whether all
    passed. The result is cached to a state file so subsequent calls (from the per-project
    override on the same job) can short-circuit.
.PARAMETER parameters
    Test parameters from Run-AlPipeline (containerName, tenant, credential, etc.). Mutated per
    job to set appName.
.PARAMETER scriptPath
    Path to the RunTestsInBcContainer.ps1 script to invoke in each background job.
.PARAMETER testType
    The test type (Legacy, UnitTest, etc.).
.PARAMETER appNamesToTest
    Ordered list of app names to dispatch. Each must be installed in the container.
.OUTPUTS
    [bool] True if every dispatched app passed; false if any failed.
#>
function Invoke-ParallelTestExecution {
    param(
        [Parameter(Mandatory=$true)]
        [Hashtable]$parameters,
        [Parameter(Mandatory=$true)]
        [string]$scriptPath,
        [Parameter(Mandatory=$true)]
        [string]$testType,
        [Parameter(Mandatory=$true)]
        [string[]]$appNamesToTest
    )

    # GitHub Actions provides a per-job temp directory ($RUNNER_TEMP) that is cleaned up between
    # jobs, so a stale state file from a previous run cannot corrupt the current run. Fall back
    # to $env:TEMP for local execution outside of CI.
    $tempDir = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { $env:TEMP }
    $stateFile = Join-Path $tempDir "parallelTests_$($parameters.containerName).json"

    # Short-circuit ONLY when a previous call ran to completion (wait+merge done). The
    # 'dispatched' flag is set before the foreach starts; if the call crashed mid-flight we must
    # NOT cache its half-baked result as success.
    if (Test-Path $stateFile) {
        try {
            $existing = Get-Content $stateFile -Raw | ConvertFrom-Json
            if ($existing.completed) {
                return [bool]$existing.finalResult
            }
        } catch {
            Write-Host "WARNING: Failed to parse state file '$stateFile' ($($_.Exception.Message)). Continuing fresh."
        }
    }

    $tenantInfo = @(Get-AvailableBcTenantInfo -containerName $parameters.containerName)
    $tenants = @($tenantInfo | ForEach-Object { $_.Id })
    Write-Host "Available tenants: $($tenants -join ', ')"

    # Build a name -> appId map so we can set extensionId per dispatch. Run-TestsInBcContainer
    # selects which app's tests to run via extensionId; appName is just descriptive. Without
    # this every job would re-run whichever extensionId Run-AlPipeline put on the parent's
    # $parameters.
    $appIdByName = @{}
    Get-BcContainerAppInfo -containerName $parameters.containerName -tenant $parameters.tenant -tenantSpecificProperties |
        Where-Object { $_.IsInstalled } |
        ForEach-Object { $appIdByName[$_.Name] = $_.AppId }

    $cleanTenantAppNames = @(
        Get-CleanTenantTestAppNames |
            Where-Object { $_ -in $appNamesToTest }
    )
    $requiredDisabledWorkItems = @(
        Get-RequiredDisabledWorkItems -Parameters $parameters -TestType $testType `
            -AppNamesToTest $cleanTenantAppNames -AppIdByName $appIdByName
    )
    $cleanTenantInfo = @(
        $tenantInfo |
            Where-Object { $_.Id -ne $parameters.tenant }
    )
    $templateDatabaseName = ""
    try {
        if ($requiredDisabledWorkItems.Count -gt 0) {
            if ($cleanTenantInfo.Count -eq 0) {
                throw "Clean RequiredTestIsolation=Disabled execution requires at least one secondary tenant."
            }
            Write-Host "Preparing clean-tenant execution for $($requiredDisabledWorkItems.Count) RequiredTestIsolation=Disabled codeunit(s)."
            $sourceTenantInfo = @($tenantInfo | Where-Object { $_.Id -eq $parameters.tenant }) | Select-Object -First 1
            if (-not $sourceTenantInfo -or [string]::IsNullOrEmpty($sourceTenantInfo.DatabaseName)) {
                throw "Could not determine the database name for source tenant '$($parameters.tenant)'."
            }
            $templateDatabaseName = New-BcTestTenantTemplate -ContainerName $parameters.containerName -SourceDatabaseName $sourceTenantInfo.DatabaseName
        }

    # dispatched=true marks "we started the foreach" - lets concurrent reads notice an in-flight
    # run. completed=false stays false until wait+merge finish; only then is finalResult valid.
    $state = [PSCustomObject]@{
        jobs = @(); dispatched = $true; completed = $false; finalResult = $false; hasFailures = $false
        transient = @(); retried = @{}; retryTenant = @{}
        rerun = @(); rerunDone = @{}; rerunBudget = (Get-AppRerunBudget); tenantCount = $tenants.Count
    }
    $state | ConvertTo-Json -Depth 5 | Set-Content $stateFile -Force

    if ($requiredDisabledWorkItems.Count -gt 0) {
        Enable-BcTestTaskScheduler -ContainerName $parameters.containerName
        try {
            $requiredDisabledPassed = Invoke-RequiredDisabledTestExecution -Parameters $parameters `
                -WorkItems $requiredDisabledWorkItems -TenantInfo $cleanTenantInfo `
                -TemplateDatabaseName $templateDatabaseName -ScriptPath $scriptPath -TestType $testType
            if (-not $requiredDisabledPassed) {
                $state.hasFailures = $true
            }
        }
        finally {
            try {
                Disable-BcTestTaskScheduler -ContainerName $parameters.containerName
            }
            finally {
                foreach ($cleanTenant in $cleanTenantInfo) {
                    Reset-BcTestTenant -ContainerName $parameters.containerName -Tenant $cleanTenant.Id `
                        -TenantDatabaseName $cleanTenant.DatabaseName -TemplateDatabaseName $templateDatabaseName
                }
            }
        }
    }

    # Single dispatch loop, FIFO. TestConfiguration.json lists the smallest app first (a cheap
    # serial warmup) and the rest longest-first (LPT, keeps the tail short). The retry cap lives in
    # Receive-TestJobResult: an app already in $state.retried is classified as Failed on a re-fail.
    $pending = @($appNamesToTest)

    # Run the first app alone and await it to warm the container before parallelizing the rest.
    # No-op for single-app/single-tenant.
    $pending = @(Invoke-WarmupDispatch -Parameters $parameters -Pending $pending -AppIdByName $appIdByName `
        -Tenants $tenants -ScriptPath $scriptPath -TestType $testType -State $state `
        -CleanTenantAppNames $cleanTenantAppNames)

    $rerunSuffixes = @()

    while ($pending.Count -gt 0 -or $state.jobs.Count -gt 0 -or $state.transient.Count -gt 0 -or $state.rerun.Count -gt 0) {
        # Promote any transient failures back into the dispatch queue. They go to the FRONT:
        # a platform race normally kills a job within a minute of dispatch, so the victim is
        # almost always one of the first (i.e. longest) apps. Appending it instead would
        # restart the longest app only after every other app had been dispatched, adding its
        # full duration to the critical path.
        if ($state.transient.Count -gt 0) {
            $toRetry = @($state.transient)
            $state.transient = @()
            $retryAppNames = @($toRetry | ForEach-Object { $_.Key })
            Write-Host "Re-queueing $($toRetry.Count) app(s) after transient platform race: $($retryAppNames -join ', ')"
            foreach ($transient in $toRetry) {
                $appName = $transient.Key
                $state.retried[$appName] = $true
                $state.retryTenant[$appName] = $transient.Tenant
                # A transient retry goes out through the normal queue and so writes to a TENANT
                # result file. Tenant files are merged before rerun files, so any rerun file this
                # app already produced would overwrite the newer result - drop it.
                if ($state.rerunDone.ContainsKey($appName)) {
                    Remove-RerunResultFile -parameters $parameters -suffix $state.rerunDone[$appName]
                }
            }
            $pending = @($retryAppNames) + @($pending)
        }

        # Reruns take priority over the normal queue, for the same tail-latency reason as above:
        # a failure is usually discovered late, so deferring its rerun would extend the run.
        if ($state.rerun.Count -gt 0) {
            $rerunItem = $state.rerun[0]
            $state.rerun = @($state.rerun | Select-Object -Skip 1)
            $rerunSuffixes += $rerunItem.suffix

            # Never reuse the tenant the app just failed on: tests are not guaranteed to clean up,
            # so its residue could re-trigger the same failure and make the rerun meaningless.
            $tenant = Wait-ForFreeTenant -state $state -tenants $tenants -excludeTenant $rerunItem.excludeTenant
            Start-TestAppDispatch -Parameters $parameters -AppName $rerunItem.appName -AppId $appIdByName[$rerunItem.appName] `
                -Tenant $tenant -ScriptPath $scriptPath -TestType $testType -State $state `
                -Verb 'Re-running' -FileSuffix $rerunItem.suffix `
                -SkipAutomaticDisabledPass:($rerunItem.appName -in $cleanTenantAppNames)
            continue
        }

        if ($pending.Count -gt 0) {
            $appName = $pending[0]
            $pending = @($pending | Select-Object -Skip 1)
            $appId = $appIdByName[$appName]
            if (-not $appId) {
                Write-Host "WARNING: Could not resolve appId for '$appName'; skipping"
                $state.hasFailures = $true
                continue
            }

            $verb = if ($state.retried.ContainsKey($appName)) { 'Re-dispatching' } else { 'Dispatching' }
            $tenant = if ($state.retryTenant.ContainsKey($appName)) {
                Wait-ForSpecificTenant -state $state -tenants $tenants -tenant $state.retryTenant[$appName]
            } else {
                Wait-ForFreeTenant -state $state -tenants $tenants
            }
            Start-TestAppDispatch -Parameters $parameters -AppName $appName -AppId $appId -Tenant $tenant `
                -ScriptPath $scriptPath -TestType $testType -State $state `
                -SkipAutomaticDisabledPass:($appName -in $cleanTenantAppNames) -Verb $verb
        } else {
            # Nothing left to dispatch; drain any still-running jobs. New transient failures and
            # reruns discovered here are picked up at the top of the next loop iteration.
            # Wait-ForAllTestJobs records failures on $state directly.
            Write-Host "All apps dispatched. Waiting for in-flight jobs to complete..."
            $null = Wait-ForAllTestJobs -state $state
        }
    }

        $allPassed = -not $state.hasFailures

        Merge-TenantTestResults -parameters $parameters -tenants $tenants `
            -workItems $requiredDisabledWorkItems -rerunSuffixes $rerunSuffixes

        # Persist final result and mark complete so subsequent override invocations short-circuit
        # to this value (and not the placeholder we wrote before dispatch).
        $state.finalResult = $allPassed
        $state.completed = $true
        $state | ConvertTo-Json -Depth 5 | Set-Content $stateFile -Force

        return $allPassed
    }
    finally {
        if ($templateDatabaseName) {
            Remove-BcTestTenantTemplate -ContainerName $parameters.containerName `
                -TemplateDatabaseName $templateDatabaseName
        }
    }
}

<#
.SYNOPSIS
    Per-project Run-AlPipeline test override: dispatches the project's test apps in parallel
    across the container's tenants and caches the result for subsequent override invocations.
.DESCRIPTION
    Run-AlPipeline calls the per-project RunTestsInBcContainer.ps1 once per test app. The first
    call computes the bucket's app list and dispatches them all in parallel; subsequent calls in
    the same job short-circuit on the cached final result. Returns the cached result if there
    are no apps to run for the project's testType.
.PARAMETER parameters
    The Run-AlPipeline parameters hashtable (containerName, tenant, credential, etc.).
.OUTPUTS
    [bool] $true if all dispatched apps passed; $false otherwise.
#>
function Invoke-PerProjectTestRun {
    param(
        [Parameter(Mandatory=$true)]
        [Hashtable]$parameters
    )

    $cached = Get-CachedTestRunResult -ContainerName $parameters.containerName
    if ($null -ne $cached) { return $cached }

    $testType = Get-ALGoSetting -Key "testType"
    $country = Get-ALGoSetting -Key "country"
    $bucketNumber = if ($testType -eq "Legacy") { Get-ALGoSetting -Key "bucketNumber" } else { 0 }

    $installed = Get-InstalledTestAppNames -ContainerName $parameters.containerName -Tenant $parameters.tenant -Country $country
    $appNamesToTest = Get-AppNamesForBucket -InstalledTestAppNames $installed -TestType $testType -BucketNumber $bucketNumber

    if ($appNamesToTest.Count -eq 0) {
        Write-Host "No test apps to run for testType '$testType' in this project."
        return $true
    }

    Write-Host "Test apps to dispatch ($($appNamesToTest.Count)): $($appNamesToTest -join ', ')"

    $parameters["returnTrueIfAllPassed"] = $true
    $script = Join-Path $PSScriptRoot "RunTestsInBcContainer.ps1" -Resolve
    return (. $script -parameters $parameters -TestType $testType -AppNamesToTest $appNamesToTest)
}

Export-ModuleMember -Function Invoke-ParallelTestExecution, Get-AvailableBcTenants, Get-CachedTestRunResult, Get-InstalledTestAppNames, Get-AppNamesForBucket, Invoke-PerProjectTestRun, Get-AppNameFromMetadata, Get-DisabledTestsForApp, Reset-BcTestTenant, Invoke-WarmupDispatch, Merge-TestResultFiles, Get-AppRerunBudget, Test-TransientTestFailure
